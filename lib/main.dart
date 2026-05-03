import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara/ui/chat_screen.dart';
import 'package:sara/ui/theme.dart';

void main() {
  runApp(const ProviderScope(child: SaraApp()));
}

class SaraApp extends StatelessWidget {
  const SaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sara Assistant',
      debugShowCheckedModeBanner: false,
      theme: SaraTheme.darkTheme,
      home: const ChatScreen(),
    );
  }
}
