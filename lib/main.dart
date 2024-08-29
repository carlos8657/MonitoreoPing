import 'package:flutter/material.dart';
import 'package:monitoreo_ip/home.dart';
import 'package:window_manager/window_manager.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  windowManager.setTitle('Monitoreo Ping'); // Cambia el título de la ventana aquí
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

