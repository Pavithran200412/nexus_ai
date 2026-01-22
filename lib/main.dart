import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/code_provider.dart';

void main() {
  runApp(const NexusAIApp());
}

class NexusAIApp extends StatelessWidget {
  const NexusAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CodeProvider()),
      ],
      child: MaterialApp(
        title: 'Nexus AI',
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: Colors.blue,
            secondary: Colors.purple,
            surface: Color(0xFF1E1E1E),
            background: Color(0xFF121212),
          ),
          scaffoldBackgroundColor: Color(0xFF121212),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}