import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OrbitGramApp());
}

class OrbitGramApp extends StatelessWidget {
  const OrbitGramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrbitGram',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF17212B),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF17212B), foregroundColor: Colors.white, elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF17212B),
          selectedItemColor: Color(0xFF2AABEE),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const AuthScreen(), // Стартовый экран - Авторизация
    );
  }
}

// --- ЭКРАН АВТОРИЗАЦИИ (ЗАГЛУШКА) ---
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

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
              const Text('OrbitGram', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 40),
              const Text('Введите ваш номер телефона', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              const TextField(
                decoration: InputDecoration(
                  hintText: '+7 999 123-45-67',
                  filled: true,
                  fillColor: Color(0xFF242F3D),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2AABEE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    // Переход на главный экран
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
                  },
                  child: const Text('Войти', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
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
  final List<Widget> _screens = [
    const ChatsPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), activeIcon: Icon(Icons.contacts), label: 'Контакты'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Настройки'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Профиль'),
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
          _buildChatTile(context, name: 'Алексей', message: 'Привет! Как дела?', time: '20:15', color: Colors.blue, isRead: true, unread: 0),
          _buildChatTile(context, name: 'Мама', message: 'Позвони мне', time: '18:30', color: Colors.pink, isRead: false, unread: 2),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2AABEE),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, {required String name, required String message, required String time, required Color color, required bool isRead, required int unread}) {
    return ListTile(
      leading: CircleAvatar(radius: 28, backgroundColor: color, child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(color: unread > 0 ? const Color(0xFF2AABEE) : Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          if (unread > 0) 
            Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF2AABEE), shape: BoxShape.circle), child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)))
          else if (isRead) 
            const Icon(Icons.done_all, color: Color(0xFF2AABEE), size: 16),
        ],
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(name: name, color: color))),
    );
  }
}

// --- ЭКРАН КОНТАКТОВ ---
class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Контакты')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('А', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          _buildContactTile('Алексей', Colors.blue),
          _buildContactTile('Анна', Colors.green),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('М', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          _buildContactTile('Мама', Colors.pink),
        ],
      ),
    );
  }

  Widget _buildContactTile(String name, Color color) {
    return ListTile(
      leading: CircleAvatar(radius: 24, backgroundColor: color, child: Text(name[0], style: const TextStyle(color: Colors.white))),
      title: Text(name, style: const TextStyle(color: Colors.white)),
    );
  }
}

// --- ЭКРАН ПРОФИЛЯ ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('Алексей Иванов', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text('+7 999 123-45-67', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF2AABEE)),
            title: const Text('Редактировать профиль', style: TextStyle(color: Color(0xFF2AABEE))),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// --- ЭКРАН НАСТРОЕК ---
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
            title: Text('Аккаунт', style: TextStyle(color: Colors.white)),
            subtitle: Text('Номер, имя пользователя, «О себе»'),
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildSettingTile(Icons.chat_bubble, Colors.orange, 'Настройки чатов', 'Обои, ночной режим, анимации'),
          _buildSettingTile(Icons.lock, Colors.green, 'Конфиденциальность', 'Время захода, устройства, ключи доступа'),
          _buildSettingTile(Icons.notifications, Colors.red, 'Уведомления', 'Звуки, звонки, счётчик сообщений'),
          _buildSettingTile(Icons.storage, Colors.blue, 'Данные и память', 'Настройки загрузки медиафайлов'),
          _buildSettingTile(Icons.folder, Colors.lightBlue, 'Папки с чатами', 'Сортировка чатов по папкам'),
          _buildSettingTile(Icons.devices, Colors.teal, 'Устройства', 'Управление активными сеансами'),
          _buildSettingTile(Icons.battery_saver, Colors.orange, 'Энергосбережение', 'Экономия энергии при низком заряде'),
          _buildSettingTile(Icons.language, Colors.purple, 'Язык', 'Русский'),
          const Divider(color: Colors.grey, height: 1),
          _buildSettingTile(Icons.star, Colors.purple, 'OrbitGram Premium', ''),
          _buildSettingTile(Icons.stars, Colors.orange, 'Звёзды OrbitGram', ''),
          _buildSettingTile(Icons.business, Colors.red, 'OrbitGram для бизнеса', ''),
          _buildSettingTile(Icons.card_giftcard, Colors.orange, 'Отправить подарок', ''),
          const Divider(color: Colors.grey, height: 1),
          _buildSettingTile(Icons.help, Colors.orange, 'Помощь', ''),
          _buildSettingTile(Icons.info, Colors.blue, 'Вопросы о OrbitGram', ''),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, Color color, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

// --- ЭКРАН ЧАТА ---
class ChatScreen extends StatefulWidget {
  final String name;
  final Color color;
  const ChatScreen({super.key, required this.name, required this.color});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _messages = [];
  late String _chatKey;

  @override
  void initState() {
    super.initState();
    _chatKey = 'chat_${widget.name}';
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _messages = prefs.getStringList(_chatKey) ?? []);
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_chatKey, _messages);
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() => _messages.add(_controller.text));
      _saveMessages();
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: widget.color, child: Text(widget.name[0], style: const TextStyle(color: Colors.white, fontSize: 14))),
            const SizedBox(width: 12),
            Text(widget.name),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFF0E1621),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: CustomPaint(
                      painter: BubblePainter(color: const Color(0xFF2B5278)),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_messages[index], style: const TextStyle(fontSize: 16, color: Colors.white)),
                            const SizedBox(height: 2),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('20:30', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                SizedBox(width: 4),
                                Icon(Icons.done_all, size: 12, color: Color(0xFF2AABEE)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: const Color(0xFF17212B),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Сообщение', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none))),
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

// --- КЛАСС ДЛЯ РИСОВАНИЯ ПУЗЫРЯ ---
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
