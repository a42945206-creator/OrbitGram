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
      ),
      home: const ChatsPage(),
    );
  }
}

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OrbitGram', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2AABEE),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text('A', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('Алексей', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Привет! Как дела?'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChatScreen(name: 'Алексей')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.pink,
              child: Text('М', style: TextStyle(color: Colors.white)),
            ),
            title: const Text('Мама', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Позвони мне'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChatScreen(name: 'Мама')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String name;
  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _messages = [];
  
  // Уникальный ключ для каждого чата
  late String _chatKey; 

  @override
  void initState() {
    super.initState();
    _chatKey = 'chat_${widget.name}';
    _loadMessages(); // Загружаем сообщения при открытии
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _messages = prefs.getStringList(_chatKey) ?? [];
    });
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_chatKey, _messages);
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(_controller.text);
      });
      _saveMessages(); // Сохраняем после добавления
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: const Color(0xFF2AABEE),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1FFC7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(_messages[index], style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Сообщение...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2AABEE)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
