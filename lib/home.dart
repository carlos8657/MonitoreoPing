import 'package:flutter/material.dart';
import 'package:monitoreo_ip/services/server_manager.dart';
import 'package:monitoreo_ip/widgets/table.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ServerManager _serverManager = ServerManager();
  bool _isAudioEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    await _serverManager.loadServers();
    setState(() {});
  }

  _handleRemoveServer(String ip) async {
    setState(() {
      _serverManager.removeServer(ip);
    });
    await _serverManager.saveServers();
    _loadServers(); // Recargar servidores después de eliminar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Stack(children: [
        Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _isAudioEnabled = !_isAudioEnabled;
              });
            },
            backgroundColor: const Color.fromARGB(255, 0, 83, 226),
            child: Icon(_isAudioEnabled ? Icons.volume_up : Icons.volume_off),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              _showAddServerDialog(context);
            },
            backgroundColor: const Color.fromARGB(255, 0, 83, 226),
            child: const Icon(Icons.add),
          ),
        ),
      ]),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 83, 226),
          flexibleSpace: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Monitoreo Servidores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 60, // Tamaño de fuente grande
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: TableWidget(
        servers: _serverManager.servers,
        onRemoveServer: _handleRemoveServer,
        isAudioEnabled: _isAudioEnabled,
      ),
    );
  }

  void _showAddServerDialog(BuildContext context) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ipController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Agregar Servidor"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese un nombre';
                    }
                    if (value.length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: ipController,
                  decoration: const InputDecoration(labelText: 'IP'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese una IP';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final name = nameController.text;
                  final ip = ipController.text;
                  final newServer = {'nombre': name, 'ip': ip, 'excluido': 'false'};
                  _serverManager.addServer(newServer);
                  await _serverManager
                      .saveServers(); // Guarda los cambios en el archivo JSON
                  setState(() {});
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Agregar"),
            ),
          ],
        );
      },
    );
  }
}
