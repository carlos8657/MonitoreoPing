import 'package:flutter/material.dart';
import 'package:monitoreo_ip/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monitoreo de Ping a Servidores',
      home: HomePage(),
    );
  }
}

