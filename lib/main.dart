import 'package:flutter/material.dart';
import 'package:ir_app/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ИК приложение',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: darkMode ? Brightness.dark : Brightness.light),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: "ИК приложение",
        onThemeBrightnessChange: ()
        {
          setState(() {
            darkMode = !darkMode;
          });
        },
      ),
    );
  }
}
