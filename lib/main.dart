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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
        title: const Text('OrbitGram'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(child: Text('А')),
            title: Text('Алексей'),
            subtitle: Text('Привет! Как дела?'),
          ),
          ListTile(
            leading: CircleAvatar(child: Text('М')),
            title: Text('Мама'),
            subtitle: Text('Позвони мне'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.message),
      ),
    );
  }
}
