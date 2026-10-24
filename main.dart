import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ошибка инициализации Firebase (если была) — показываем её на экране вместо падения.
String? firebaseInitError;

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
    firebaseInitError = e.toString();
    debugPrint('Ошибка Firebase: $e');
  }
  runApp(ChangeNotifierProvider(create: (context) => ThemeProvider(), child: const OrbitGramApp()));
}

// Первая буква имени для аватарки (безопасно для пустых строк и эмодзи).
String _initial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

// --- УПРАВЛЕНИЕ ТЕМОЙ ---
class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;
  ThemeProvider() {
    _loadTheme();
  }
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
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
      home: firebaseInitError != null ? InitErrorScreen(message: firebaseInitError!) : const AuthGate(),
    );
  }
}

// --- ЭКРАН ОШИБКИ ИНИЦИАЛИЗАЦИИ ---
class InitErrorScreen extends StatelessWidget {
  final String message;
  const InitErrorScreen({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Не удалось запустить Firebase:\n$message', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

// --- ВЫБОР ЭКРАНА ПО СОСТОЯНИЮ АВТОРИЗАЦИИ ---
// Если пользователь уже вошёл (сессия сохраняется), сразу открываем приложение.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data != null) return const MainScreen();
        return const AuthScreen();
      },
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите ваше имя')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // После входа AuthGate сам переключит экран на MainScreen.
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'uid': uid,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.send, size: 80, color: Color(0xFF2AABEE)),
              const SizedBox(height: 20),
              const Text('OrbitGram', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _signIn(),
                decoration: const InputDecoration(hintText: 'Введите ваше имя', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2AABEE),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
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
  final List<Widget> _screens = const [ChatsPage(), ContactsPage(), SettingsPage()];

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

  // В документе чата хранятся имена обоих участников ('names': {uid: имя}).
  // Показываем имя собеседника, а не своё. 'chatName' — запасной вариант для старых чатов.
  String _chatTitle(Map<String, dynamic> chat, String myUid) {
    final names = chat['names'];
    if (names is Map) {
      for (final entry in names.entries) {
        final value = entry.value;
        if (entry.key != myUid && value is String && value.isNotEmpty) return value;
      }
    }
    final legacy = chat['chatName'];
    return (legacy is String && legacy.isNotEmpty) ? legacy : 'Чат';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('OrbitGram')),
        body: const Center(child: Text('Вы не авторизованы')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('OrbitGram')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chats = snapshot.data!.docs;
          if (chats.isEmpty) return const Center(child: Text('У вас пока нет чатов. Перейдите в Контакты.'));
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data();
              final title = _chatTitle(chat, currentUser.uid);
              return ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF2AABEE), child: Icon(Icons.person, color: Colors.white)),
                title: Text(title),
                subtitle: const Text('Нажмите, чтобы открыть'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen(chatId: chats[index].id, title: title)),
                ),
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

  Future<void> _openChat(BuildContext context, User me, String otherUid, String otherName) async {
    final chatId = me.uid.compareTo(otherUid) < 0 ? '${me.uid}_$otherUid' : '${otherUid}_${me.uid}';
    final db = FirebaseFirestore.instance;
    try {
      final meDoc = await db.collection('users').doc(me.uid).get();
      final myName = (meDoc.data()?['name'] as String?) ?? 'Без имени';
      await db.collection('chats').doc(chatId).set({
        'participants': [me.uid, otherUid],
        'names': {me.uid: myName, otherUid: otherName},
      }, SetOptions(merge: true));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось открыть чат: $e')));
      }
      return;
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId, title: otherName)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Контакты')),
        body: const Center(child: Text('Вы не авторизованы')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Контакты')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs.where((doc) => doc.id != currentUser.uid).toList();
          if (users.isEmpty) return const Center(child: Text('Пока нет других пользователей.'));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final rawName = (userDoc.data()['name'] as String?)?.trim() ?? '';
              final name = rawName.isEmpty ? 'Без имени' : rawName;
              return ListTile(
                leading: CircleAvatar(child: Text(_initial(name))),
                title: Text(name),
                onTap: () => _openChat(context, currentUser, userDoc.id, name),
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
  final String title;
  const ChatScreen({super.key, required this.chatId, this.title = 'Чат'});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // Очищаем поле сразу, чтобы двойное нажатие не отправило сообщение дважды.
    _controller.clear();
    try {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось отправить: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // Новые сообщения сверху + reverse: список всегда открыт на последних сообщениях.
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data();
                    final isMe = msg['senderId'] == myUid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF2B5278) : Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text((msg['text'] as String?) ?? '', style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            // SafeArea — чтобы поле ввода не уезжало под системную панель навигации.
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(hintText: 'Сообщение'),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.send, color: Color(0xFF2AABEE)), onPressed: _sendMessage),
                  ],
                ),
              ),
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

  Future<void> _signOut(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Анонимный аккаунт после выхода восстановить нельзя, поэтому удаляем его
    // карточку из 'users', иначе в контактах копятся «призраки» с тем же именем.
    try {
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      }
    } catch (e) {
      debugPrint('Не удалось удалить профиль: $e');
    }
    // AuthGate сам покажет экран входа.
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: const Center(child: Text('Вы не авторизованы')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
            builder: (context, snapshot) {
              String name;
              if (snapshot.hasError) {
                name = 'Ошибка загрузки';
              } else if (!snapshot.hasData) {
                name = 'Загрузка...';
              } else {
                name = (snapshot.data!.data()?['name'] as String?) ?? 'Без имени';
              }
              return ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF2AABEE),
                  child: Text(_initial(name), style: const TextStyle(color: Colors.white, fontSize: 24)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Colors.purple),
            title: const Text('Темная тема'),
            value: themeProvider.isDark,
            onChanged: (value) => themeProvider.toggleTheme(),
          ),
          const Divider(),

          // Блок Звёзд
          ListTile(
            leading: const Icon(Icons.stars, color: Colors.orange, size: 28),
            title: const Text('Orbit Stars', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Магазин звёзд'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StarsShopScreen())),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Выйти', style: TextStyle(color: Colors.red)),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}

// --- МАГАЗИН ЗВЁЗД ---
class StarsShopScreen extends StatelessWidget {
  const StarsShopScreen({super.key});

  // Пакеты считаются один раз, а не при каждой перерисовке экрана.
  static final List<Map<String, dynamic>> _packages = _generatePackages();

  static List<Map<String, dynamic>> _generatePackages() {
    final List<Map<String, dynamic>> packages = [];
    int stars = 100;
    int price = 15;

    while (stars <= 1000000) {
      packages.add({
        'stars': stars,
        'price': price,
        'label': '$stars - $price ₽',
      });
      stars += 1000;
      price += 5;
    }
    return packages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orbit Stars')),
      body: ListView.builder(
        itemCount: _packages.length,
        itemBuilder: (context, index) {
          final pkg = _packages[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber, size: 36),
              title: Text('${pkg['stars']} звёзд', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2AABEE)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Оплата звёзд'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Вы покупаете: ${pkg['stars']} звёзд', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text('Сумма к оплате: ${pkg['price']} ₽', style: const TextStyle(fontSize: 16)),
                          const Divider(height: 30),
                          const Text('Реквизиты для перевода:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text('📞 Номер: +7 978 474 52 38'), // ВАШ НОМЕР
                          const Text('🏦 Банк: Т-Банк (Тинькофф)'),
                          const SizedBox(height: 20),
                          const Text(
                            'После перевода отправьте чек в поддержку, и звёзды будут зачислены на ваш баланс.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Закрыть'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(dialogContext);
                            messenger.showSnackBar(const SnackBar(content: Text('Заявка отправлена! Ожидайте зачисления.')));
                          },
                          child: const Text('Я оплатил'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('${pkg['price']} ₽', style: const TextStyle(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }
}
