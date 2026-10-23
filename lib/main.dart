import 'package:flutter/material.dart';

void main() {
  runApp(const OrbitGramApp());
}

class OrbitGramApp extends StatelessWidget {
  const OrbitGramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrbitGram',
      debugShowCheckedModeBanner: false, // Убирает красную полоску "DEBUG" в углу
      theme: ThemeData(
        // Делаем цвета более похожими на современные мессенджеры
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2AABEE)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
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
        title: const Text(
          'OrbitGram',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF2AABEE), // Синий цвет как в Telegram
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Красивая карточка чата
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue,
              child: Text('A', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            title: const Text(
              'Алексей',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: const Text(
              'Привет! Как дела?',
              style: TextStyle(color: Colors.grey),
            ),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('20:04', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 4),
                Icon(Icons.done_all, color: Colors.blue, size: 16), // Галочки прочитано
              ],
            ),
          ),
          const Divider(height: 1, indent: 80), // Линия-разделитель
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.pink,
              child: Text('М', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            title: const Text(
              'Мама',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: const Text(
              'Позвони мне, как освободишься',
              style: TextStyle(color: Colors.grey),
            ),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('18:30', style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 4),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.green,
                  child: Text('2', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2AABEE),
        child: const Icon(Icons.edit, color: Colors.white), // Иконка "Написать"
      ),
    );
  }
}
