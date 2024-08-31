import 'package:flutter/material.dart';
import 'package:monitoreo_ip/services/server_manager.dart';
import 'package:monitoreo_ip/widgets/table.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ServerManager serverManager = ServerManager();
  bool isAudioEnabled = true;
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    loadServers();
  }

  Future<void> loadServers() async {
    await serverManager.loadServers();
    setState(() {});
  }

  void showAddServerDialog(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ipController = TextEditingController();
    final FocusNode nodoNombre = FocusNode();
    String tipoServidor = 'servidor';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(nodoNombre);
        });
        return AlertDialog(
          title: const Text("Agregar Servidor"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo de texto para el nombre
                SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    focusNode: nodoNombre,
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
                    onFieldSubmitted: (value) {
                      // Enviar el formulario cuando se presiona Enter en el campo de texto
                      handleAddServer(
                          context, formKey, nameController, ipController, tipoServidor);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Campo de texto para la dirección IP
                SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: ipController,
                    decoration: const InputDecoration(labelText: 'IP'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese una IP';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) {
                      // Enviar el formulario cuando se presiona Enter en el campo de texto
                      handleAddServer(
                          context, formKey, nameController, ipController, tipoServidor);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Campo para tipo de servidor
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField(
                    decoration:
                        const InputDecoration(labelText: 'Tipo de Servidor'),
                    items: const [
                      DropdownMenuItem(
                          value: 'servidor', child: Text('Servidor')),
                      DropdownMenuItem(
                          value: 'dispositivo', child: Text('Dispositivo')),
                    ],
                    value: tipoServidor,
                    onChanged: (value) {
                      setState(() {
                        tipoServidor = value.toString();
                      });
                    },
                  ),
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
              onPressed: () {
                handleAddServer(context, formKey, nameController, ipController, tipoServidor);
              },
              child: const Text("Agregar"),
            ),
          ],
        );
      },
    );
  }

  void handleAddServer(
    BuildContext context,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController ipController,
    String tipoServidor,
  ) async {
    if (formKey.currentState?.validate() ?? false) {
      final name = nameController.text;
      final ip = ipController.text;
      final serverExists = serverManager.servers.any((s) => s['ip'] == ip);
      String id = uuid.v4();
      if (serverExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El servidor ya existe'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final newServer = {'id': id,  'nombre': name, 'ip': ip, 'excluido': 'false', 'tipo': tipoServidor};
      serverManager.addServer(newServer);
      await serverManager.saveServers(); // Guarda los cambios en el archivo JSON
      setState(() {});
      Navigator.of(context).pop();
    }
  }

  void showRemoveServerDialog(String ip) async {
    final FocusNode focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(focusNode);
        });
        return AlertDialog(
          title: const Text("Eliminar Servidor"),
          content:
              const Text("¿Está seguro de que desea eliminar este servidor?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                handleRemoveServer(context, ip);
              },
              focusNode: focusNode,
              child: const Text("Eliminar"),
            ),
          ],
          actionsOverflowButtonSpacing: 1,
        );
      },
    );
  }

  void handleRemoveServer(BuildContext context, String id) async {
    serverManager.removeServer(id);
    await serverManager.saveServers();
    loadServers();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  void showEditServerDialog(String id) async {
    // Obtener el servidor a editar
    final server = serverManager.servers.firstWhere((s) => s['id'] == id);
    // Crear llave obligatoria para el formulario
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Controladores para los campos de texto  y asignar valores iniciales
    final TextEditingController nameController = TextEditingController(text: server['nombre']);
    final TextEditingController ipController = TextEditingController(text: server['ip']);
    String tipoServidor = 'servidor';
    final FocusNode nameFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(nameFocusNode);
        });
        return AlertDialog(
          title: const Text("Editar Servidor"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo de texto para el nombre
                SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    focusNode: nameFocusNode,
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) {
                      // Validar que el campo no este vacio
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese un nombre';
                      }
                      // Validar que el nombre tenga al menos 3 caracteres
                      if (value.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) {
                      handleEditServer(
                          formKey, nameController, ipController, server, tipoServidor);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Campo de texto para la dirección IP
                SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: ipController,
                    decoration: const InputDecoration(labelText: 'IP'),
                    validator: (value) {
                      // Validar que el campo no este vacio
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese una IP';
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) {
                      handleEditServer(
                          formKey, nameController, ipController, server, tipoServidor);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Campo para tipo de servidor
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField(
                    decoration:
                        const InputDecoration(labelText: 'Tipo de Servidor'),
                    items: const [
                      DropdownMenuItem(
                          value: 'servidor', child: Text('Servidor')),
                      DropdownMenuItem(
                          value: 'dispositivo', child: Text('Dispositivo')),
                    ],
                    value: tipoServidor,
                    onChanged: (value) {
                      setState(() {
                        tipoServidor = value.toString();
                      });
                    },
                  ),
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
                handleEditServer(
                    formKey, nameController, ipController, server, tipoServidor);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void handleEditServer(
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController ipController,
    Map<String, String> server,
    String tipoServidor,
  ) async {
    // Verificar que cumpla con las validaciones
    if (formKey.currentState?.validate() ?? false) {
      // Obtener informacion actualizada del servidor
      final updatedName = nameController.text;
      final updatedIp = ipController.text;
      final serverExists = serverManager.servers.any((s) => s['ip'] == updatedIp && s['id'] != server['id']);
      if (serverExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El servidor ya existe'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Crear un objeto del servidor a actualizar
      final updatedServer = {
        'id': server['id'] ?? '',
        'nombre': updatedName,
        'ip': updatedIp,
        'excluido': server['excluido'] ?? 'false',
        'tipo': tipoServidor,
      };

      setState(() {
        serverManager.updateServer(server['id'] ?? '', updatedServer);
      });
      // Recargar servidores después de actualizar
      loadServers();
      // Cerrar el dialogo
      Navigator.of(context).pop();
    }
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
                isAudioEnabled = !isAudioEnabled;
              });
            },
            backgroundColor: const Color.fromARGB(255, 0, 83, 226),
            child: Icon(isAudioEnabled ? Icons.volume_up : Icons.volume_off),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              showAddServerDialog(context);
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
        servers: serverManager.servers,
        onRemoveServer: showRemoveServerDialog,
        onEditServer: showEditServerDialog,
        isAudioEnabled: isAudioEnabled,
      ),
    );
  }
}
