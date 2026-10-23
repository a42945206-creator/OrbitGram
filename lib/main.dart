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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2AABEE)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

// --- ГЛАВНЫЙ ЭКРАН С НИЖНЕЙ ПАНЕЛЬЮ ---
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
        selectedItemColor: const Color(0xFF2AABEE),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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
        backgroundColor: const Color(0xFF2AABEE),
        foregroundColor: Colors.white,
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
      leading: CircleAvatar(radius: 28, backgroundColor: color, child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(color: unread > 0 ? const Color(0xFF2AABEE) : Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          if (unread > 0) Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF2AABEE), shape: BoxShape.circle), child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)))
          else if (isRead) const Icon(Icons.done_all, color: Colors.blue, size: 16),
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
      appBar: AppBar(title: const Text('Контакты'), backgroundColor: const Color(0xFF2AABEE), foregroundColor: Colors.white),
      body: const Center(child: Text('Список контактов появится здесь')),
    );
  }
}

// --- ЭКРАН НАСТРОЕК (ДЕТАЛИЗИРОВАННЫЙ) ---
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки'), backgroundColor: const Color(0xFF2AABEE), foregroundColor: Colors.white),
      body: ListView(
        children: [
          // Профиль
          const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
            title: Text('Аккаунт'),
            subtitle: Text('Номер, имя пользователя, «О себе»'),
          ),
          const Divider(),
          // Основные настройки
          const ListTile(leading: Icon(Icons.chat_bubble, color: Colors.orange), title: Text('Настройки чатов'), subtitle: Text('Обои, ночной режим, анимации')),
          const ListTile(leading: Icon(Icons.lock, color: Colors.green), title: Text('Конфиденциальность'), subtitle: Text('Время захода, устройства, ключи доступа')),
          const ListTile(leading: Icon(Icons.notifications, color: Colors.red), title: Text('Уведомления'), subtitle: Text('Звуки, звонки, счётчик сообщений')),
          const ListTile(leading: Icon(Icons.storage, color: Colors.blue), title: Text('Данные и память'), subtitle: Text('Настройки загрузки медиафайлов')),
          const ListTile(leading: Icon(Icons.folder, color: Colors.lightBlue), title: Text('Папки с чатами'), subtitle: Text('Сортировка чатов по папкам')),
          const ListTile(leading: Icon(Icons.devices, color: Colors.teal), title: Text('Устройства'), subtitle: Text('Управление активными сеансами')),
          const ListTile(leading: Icon(Icons.battery_saver, color: Colors.orange), title: Text('Энергосбережение'), subtitle: Text('Экономия энергии при низком заряде')),
          const ListTile(leading: Icon(Icons.language, color: Colors.purple), title: Text('Язык'), subtitle: Text('Русский')),
          
          const Divider(),
          // Блок Premium и Звёзды (как на вашем скриншоте)
          const ListTile(leading: Icon(Icons.star, color: Colors.purple), title: Text('OrbitGram Premium')),
          const ListTile(leading: Icon(Icons.stars, color: Colors.orange), title: Text('Звёзды OrbitGram')),
          const ListTile(leading: Icon(Icons.business, color: Colors.red), title: Text('OrbitGram для бизнеса')),
          const ListTile(leading: Icon(Icons.card_giftcard, color: Colors.orange), title: Text('Отправить подарок')),
          
          const Divider(),
          // Помощь
          const ListTile(leading: Icon(Icons.help, color: Colors.orange), title: Text('Помощь')),
          const ListTile(leading: Icon(Icons.info, color: Colors.blue), title: Text('Вопросы о OrbitGram')),
        ],
      ),
    );
  }
}

// --- ЭКРАН ПРОФИЛЯ ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль'), backgroundColor: const Color(0xFF2AABEE), foregroundColor: Colors.white),
      body: const Center(child: Text('Ваш профиль')),
    );
  }
}

// --- ЭКРАН ПЕРЕПИСКИ (С ПУЗЫРЯМИ КАК В TELEGRAM) ---
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
        backgroundColor: const Color(0xFF2AABEE),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: widget.color, child: Text(widget.name[0], style: const TextStyle(color: Colors.white, fontSize: 14))),
            const SizedBox(width: 12),
            Text(widget.name),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFE5DDD5), // Цвет фона чата как в Telegram
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  // Используем CustomPaint для создания пузыря с хвостиком
                  return Align(
                    alignment: Alignment.centerRight,
                    child: CustomPaint(
                      painter: BubblePainter(color: const Color(0xFFE1FFC7)),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_messages[index], style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('20:30', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(width: 4),
                                const Icon(Icons.done_all, size: 12, color: Colors.blue),
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
              color: Colors.white,
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

    // Рисуем прямоугольник с закругленными углами
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - tailHeight),
      Radius.circular(radius),
    ));

    // Рисуем хвостик справа внизу
    path.moveTo(size.width - tailWidth, size.height - tailHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - tailWidth - 4, size.height - tailHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
