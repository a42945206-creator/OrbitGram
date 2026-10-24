import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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
        'photoUrl': '',
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
              final photoUrl = user['photoUrl'] ?? '';
              return ListTile(
                leading: photoUrl.isNotEmpty 
                  ? CircleAvatar(backgroundImage: NetworkImage(photoUrl)) 
                  : CircleAvatar(child: Text(user['name'][0])),
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

// --- ЭКРАН ЧАТА (КРАСИВЫЙ) ---
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
      appBar: AppBar(
        title: const Text('Чат'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF0E1621) 
              : const Color(0xFFE5DDD5),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('timestamp', descending: false).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data() as Map<String, dynamic>;
                      final isMe = msg['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                      final timestamp = msg['timestamp'] as Timestamp?;
                      final timeStr = timestamp != null ? DateFormat.Hm().format(timestamp.toDate()) : '';
                      
                      return AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: CustomPaint(
                          painter: BubblePainter(
                            color: isMe 
                              ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2B5278) : const Color(0xFFE1FFC7)) 
                              : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF182533) : Colors.white),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['text'] ?? '', 
                                  style: TextStyle(
                                    color: isMe && Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.done_all, size: 12, color: Color(0xFF2AABEE)),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Сообщение',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF242F3D) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2AABEE),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- КЛАСС ДЛЯ РИСОВАНИЯ ПУЗЫРЯ С ХВОСТИКОМ ---
class BubblePainter extends CustomPainter {
  final Color color;
  BubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final radius = 12.0;
    final tailWidth = 8.0;
    final tailHeight = 8.0;

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - tailHeight),
      Radius.circular(radius),
    ));

    path.moveTo(size.width - tailWidth, size.height - tailHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - tailWidth - 4, size.height - tailHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- НАСТРОЙКИ ---
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        File file = File(pickedFile.path);
        String fileName = '${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // ИСПРАВЛЕНО: используем правильный тип Reference из новой версии
        Reference ref = FirebaseStorage.instance.ref().child('user_photos').child(fileName);
        await ref.putFile(file);
        String downloadUrl = await ref.getDownloadURL();
        
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
          'photoUrl': downloadUrl,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фото профиля обновлено!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

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
              String photoUrl = '';
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['name'] ?? 'Без имени';
                photoUrl = data['photoUrl'] ?? '';
              }
              return ListTile(
                leading: _isUploading 
                  ? const CircleAvatar(child: CircularProgressIndicator())
                  : GestureDetector(
                      onTap: _pickImage,
                      child: photoUrl.isNotEmpty 
                        ? CircleAvatar(radius: 30, backgroundImage: NetworkImage(photoUrl))
                        : CircleAvatar(radius: 30, backgroundColor: const Color(0xFF2AABEE), child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 24))),
                    ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: const Text('Нажмите на аватарку, чтобы сменить фото'),
                trailing: const Icon(Icons.camera_alt, color: Colors.grey),
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
