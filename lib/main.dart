import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- ИНИЦИАЛИЗАЦИЯ FIREBASE ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCD7VrCzpOqoemrxZjM_G-GhOTKff_MaGY",
        appId: "1:644523161146:android:625ffa87768fae311b2703",
        messagingSenderId: "644523161146",
        projectId: "orbitgram-18ed4",
      ),
    );
  } catch (e) {
    print('Ошибка Firebase: $e');
  }
  runApp(ChangeNotifierProvider(create: (context) => ThemeProvider(), child: const OrbitGramApp()));
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

class OrbitGramApp extends StatelessWidget {
  const OrbitGramApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'OrbitGram',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, scaffoldBackgroundColor: Colors.white),
      darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF17212B)),
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
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите ваше имя')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'uid': userCredential.user!.uid,
      });
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
              TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Введите ваше имя', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2AABEE), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                onPressed: _signIn,
                child: const Text('Войти', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ГЛАВНЫЙ ЭКРАН ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const ChatsPage(), const ContactsPage(), const SettingsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Чаты'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), label: 'Контакты'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Настройки'),
        ],
      ),
    );
  }
}

// --- ЭКРАН ЧАТОВ ---
class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('OrbitGram')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chats = snapshot.data!.docs;
          if (chats.isEmpty) return const Center(child: Text('У вас пока нет чатов. Перейдите в Контакты.'));
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF2AABEE), child: Icon(Icons.person, color: Colors.white)),
                title: Text(chat['chatName'] ?? 'Чат'),
                subtitle: const Text('Нажмите, чтобы открыть'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatId: chats[index].id))),
              );
            },
          );
        },
      ),
    );
  }
}

// --- ЭКРАН КОНТАКТОВ ---
class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Контакты')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs.where((doc) => doc.id != currentUser?.uid).toList();
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(child: Text(user['name'][0])),
                title: Text(user['name']),
                onTap: () async {
                  final chatId = currentUser!.uid.compareTo(users[index].id) < 0 
                      ? '${currentUser.uid}_${users[index].id}' 
                      : '${users[index].id}_${currentUser.uid}';
                  await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
                    'participants': [currentUser.uid, users[index].id],
                    'chatName': '${user['name']}',
                  }, SetOptions(merge: true));
                  if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId)));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- ЭКРАН ЧАТА ---
class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
        'text': _controller.text,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': FirebaseAuth.instance.currentUser?.uid,
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чат')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                    final timestamp = msg['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null ? DateFormat.Hm().format(timestamp.toDate()) : '';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: isMe ? const Color(0xFF2B5278) : Colors.grey[800], borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Сообщение'))),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF2AABEE)), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- НАСТРОЙКИ ---
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              String name = 'Загрузка...';
              if (snapshot.hasData && snapshot.data!.exists) {
                name = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Без имени';
              }
              return ListTile(
                leading: CircleAvatar(radius: 30, backgroundColor: const Color(0xFF2AABEE), child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 24))),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: const Text('Номер, имя пользователя, «О себе»'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
          const Divider(),
          
          _buildTile(context, Icons.chat_bubble, Colors.orange, 'Настройки чатов', 'Обои, ночной режим, анимации'),
          _buildTile(context, Icons.lock, Colors.green, 'Конфиденциальность', 'Время захода, устройства, ключи доступа'),
          _buildTile(context, Icons.notifications, Colors.red, 'Уведомления', 'Звуки, звонки, счётчик сообщений'),
          _buildTile(context, Icons.storage, Colors.blue, 'Данные и память', 'Настройки загрузки медиафайлов'),
          _buildTile(context, Icons.folder, Colors.lightBlue, 'Папки с чатами', 'Сортировка чатов по папкам'),
          _buildTile(context, Icons.devices, Colors.teal, 'Устройства', 'Управление активными сеансами'),
          _buildTile(context, Icons.battery_saver, Colors.orange, 'Энергосбережение', 'Экономия энергии при низком заряде'),
          _buildTile(context, Icons.language, Colors.purple, 'Язык', 'Русский'),
          
          const Divider(),
          
          _buildTile(context, Icons.star, Colors.purple, 'OrbitGram Premium', 'Подписка и эксклюзивные функции'),
          _buildTile(context, Icons.stars, Colors.orange, 'Orbit Stars', 'Магазин звёзд и покупки'),
          _buildTile(context, Icons.card_giftcard, Colors.pink, 'Отправить подарок', 'Порадуйте друга'),
          
          const Divider(),
          
          _buildTile(context, Icons.help, Colors.orange, 'Помощь', 'Вопросы и ответы'),
          _buildTile(context, Icons.info, Colors.blue, 'Вопросы о OrbitGram', 'Версия приложения'),
          
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

  Widget _buildTile(BuildContext context, IconData icon, Color color, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Раздел "$title" в разработке')));
      },
    );
  }
}
