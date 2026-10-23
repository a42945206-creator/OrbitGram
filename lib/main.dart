import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- ИНИЦИАЛИЗАЦИЯ FIREBASE ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const OrbitGramApp(),
    ),
  );
}

// --- УПРАВЛЕНИЕ ТЕМОЙ ---
class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;
  ThemeProvider() { _loadTheme(); }
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? true;
    notifyListeners();
  }
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }
}

// --- ГЛАВНЫЙ КЛАСС ---
class OrbitGramApp extends StatelessWidget {
  const OrbitGramApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'OrbitGram',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, scaffoldBackgroundColor: Colors.white, appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0)),
      darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF17212B), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF17212B), foregroundColor: Colors.white, elevation: 0)),
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const AuthScreen(),
    );
  }
}

// --- ЭКРАН АВТОРИЗАЦИИ ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.send, size: 80, color: Color(0xFF2AABEE)),
              const SizedBox(height: 20),
              const Text('OrbitGram', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2AABEE), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                onPressed: _signInAnonymously,
                child: const Text('Войти анонимно', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ГЛАВНЫЙ ЭКРАН С 5 ВКЛАДКАМИ ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ChatsPage(),
    const CallsPage(),
    const ContactsPage(),
    const SettingsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Чаты'),
          BottomNavigationBarItem(icon: Icon(Icons.call_outlined), activeIcon: Icon(Icons.call), label: 'Звонки'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), activeIcon: Icon(Icons.contacts), label: 'Контакты'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Настройки'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

// --- ЭКРАН ЧАТОВ (С ПОДКЛЮЧЕНИЕМ К FIREBASE) ---
class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OrbitGram', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF2AABEE), child: Text('O', style: TextStyle(color: Colors.white))),
            title: const Text('Общий чат'),
            subtitle: const Text('Нажми, чтобы проверить связь'),
            trailing: const Icon(Icons.done_all, color: Color(0xFF2AABEE), size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2AABEE),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

// --- ЭКРАН ЧАТА (FIRESTORE) ---
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _messagesRef = FirebaseFirestore.instance.collection('messages');

  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty) {
      await _messagesRef.add({
        'text': _controller.text,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: Colors.blue, child: Text('O', style: TextStyle(color: Colors.white, fontSize: 14))),
            SizedBox(width: 12),
            Text('Общий чат'),
          ],
        ),
      ),
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0E1621) : const Color(0xFFE5DDD5),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _messagesRef.orderBy('timestamp', descending: false).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data() as Map<String, dynamic>;
                      final isMe = msg['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe 
                                ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B5278) : const Color(0xFFE1FFC7))
                                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF182533) : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMe ? 12 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 12),
                            ),
                          ),
                          child: Text(msg['text'] ?? '', style: TextStyle(color: isMe && Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Сообщение', border: InputBorder.none))),
                  IconButton(icon: const Icon(Icons.send, color: Color(0xFF2AABEE)), onPressed: _sendMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ОСТАЛЬНЫЕ ЭКРАНЫ (ЗАГЛУШКИ) ---
class CallsPage extends StatelessWidget { const CallsPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Звонки (в разработке)'))); }
class ContactsPage extends StatelessWidget { const ContactsPage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Контакты (в разработке)'))); }
class ProfilePage extends StatelessWidget { const ProfilePage({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Профиль (в разработке)'))); }

// --- НАСТРОЙКИ (С РАБОЧИМ ПЕРЕКЛЮЧАТЕЛЕМ ТЕМЫ И ВЫХОДОМ) ---
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Темная тема'),
            value: themeProvider.isDark,
            onChanged: (value) => themeProvider.toggleTheme(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Выйти', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
            },
          ),
        ],
      ),
    );
  }
}
