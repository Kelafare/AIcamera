import 'package:flutter/material.dart';

import 'shell/main_shell.dart';

class ComiraApp extends StatelessWidget {
  const ComiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comira',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
