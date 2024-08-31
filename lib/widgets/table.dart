import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:monitoreo_ip/services/ping.dart';
import 'package:monitoreo_ip/services/server_manager.dart';
import 'package:window_manager/window_manager.dart';

class TableWidget extends StatefulWidget {
  const TableWidget({
    super.key,
    required this.servers,
    required this.onRemoveServer, // Añadir el callback
    required this.isAudioEnabled,
    required this.onEditServer, // Añadir el callback
  });

  final List<Map<String, String>> servers;
  final Function(String) onRemoveServer; // Callback para eliminar servidor
  final bool isAudioEnabled;
  final Function(String) onEditServer;

  @override
  _TableWidgetState createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  final PingService _pingService = PingService();
  final Map<String, String> _pingResults = {};
  final Map<String, String> _serverStatus = {};
  bool _isAlertVisible = false;
  OverlayEntry? _overlayEntry;
  late AudioPlayer _player;
  final Map<String, int> pingFallidos = {};
  final Map<String, int> numeroAlertas = {};
  List<Map<String, String>> serversError = [];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.loop);
    _startPing();
  }

  void restoreWindow() async {
    if (await windowManager.isMinimized()) {
      windowManager.restore();
      windowManager.focus();
    }
  }

  void _startPing() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      for (var server in widget.servers) {
        // Obtener la IP del servidor
        final ip = server['ip'];

        // Comprobar que no traiga ip
        if (ip != null) {
          _pingService.pingHost(ip).then((result) {
            // Comprobar si el ping falló
            if (result['media'] == 'Ping fallido' ||
                result['media'] == 'Error') {
              // Incrementar el contador de ping fallidos
              pingFallidos[ip] = (pingFallidos[ip] ?? 0) + 1;
            } else {
              // Restablecer servidor si se recupera
              pingFallidos[ip] = 0;

              serversError.remove(server);
            }
            // Comprobar si trae ping o no para mostrar el circulo verde o rojo
            final isError = (result['media'] == 'Ping fallido' ||
                result['media'] == 'Error');

            setState(() {
              // Actualizar los resultados del ping
              _pingResults[ip] = result['media'] ?? 'Error';
              _serverStatus[ip] = isError ? 'Offline' : 'Online';
            });

            // Verificar numero de ping fallidos para agregar el servidor a la lista de servidores con error
            // Verificar si el servidor ya esta en la lista de servidores con error para no agregarlo de nuevo
            // Verificar si el servidor ya esta excluido del contador de alertas
            if (pingFallidos[ip]! >= 20 && !serversError.contains(server)) {
              serversError.add(server);
            }

            // Mostrar alerta si hay servidores con error
            if (serversError.isNotEmpty) {
              // Agregar 1 al contador de alertas para solo mostrar 3 veces la alerta
              numeroAlertas[ip] = (numeroAlertas[ip] ?? 0) + 1;
              _showErrorAlert(serversError);
            }
          });
        }
      }
    });
  }

  void _showErrorAlert(List<Map<String, String>> servers) {
    // Verificar si ya se esta mostrando una alerta
    if (_isAlertVisible) return; // Evita mostrar múltiples alertas

    // Verificar si ya se mostraron 3 alertas de esos servidores para no mostrarlos de nuevo
    for (var server in servers) {
      final ip = server['ip'];
      if (numeroAlertas[ip]! >= 3) {
        server['excluido'] = 'true';
      }
    }

    // Crear lista de servidores con error que no se han excluido
    List<Map<String, String>> serversErrorSinExcluir = servers.where((server) => server['excluido'] != 'true').toList();

    if (serversErrorSinExcluir.isEmpty) {
      return;
    }

    if (widget.isAudioEnabled) {
      _player.play(AssetSource('alerta.mp3'));
      // Cambiar el estado de que hay una alerta visible
      setState(() {
        _isAlertVisible = true;
      });
    }
    int columns = (serversErrorSinExcluir.length / 5)
        .ceil(); // Calcula el número de columnas 5 servidores por columna

    _overlayEntry?.remove(); // Eliminar la notificación anterior si existe
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.red.withOpacity(0.9), // Fondo rojo con opacidad
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Error en el Ping',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              columns, // Número de columnas dinámico
                          childAspectRatio:
                              3, // Ajusta la relación de aspecto de los elementos
                        ),
                        itemCount: serversErrorSinExcluir.length,
                        itemBuilder: (context, index) {
                          final server = serversErrorSinExcluir[index];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Center(
                                child: Text(
                                  'Servidor: ${server['nombre']}\nIP: ${server['ip']}\nError: No ping',
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _player.stop();
                        _overlayEntry?.remove();
                        _overlayEntry = null;
                        setState(() {
                          _isAlertVisible = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Tabla de Servidores
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Servidores',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    // Usar Expanded para ajustarse al espacio disponible
                    child: Table(
                      border: TableBorder.all(),
                      columnWidths: const <int, TableColumnWidth>{
                        0: FlexColumnWidth(2), // Campo de Nombre más ancho
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(0.8),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('NOMBRE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('IP',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('MS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                            ),
                          ],
                        ),
                        ...widget.servers
                            .where((server) => server['tipo'] == 'servidor')
                            .map((server) {
                          final ip = server['ip'];
                          return TableRow(
                            children: [
                              Row(
                                children: [
                                  // Indicador de estado
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _pingResults[server['ip']] ==
                                                    'Error' ||
                                                _pingResults[server['ip']] ==
                                                    'Ping fallido' ||
                                                _pingResults[server['ip']] ==
                                                    null
                                            ? Colors.red
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                  ),
                                  // Nombre del servidor
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        server['nombre'] ?? '',
                                        style: const TextStyle(fontSize: 22),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  // Boton de editar
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      widget.onEditServer(server['id']!);
                                    },
                                  ),
                                  // Boton de eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      widget.onRemoveServer(server['id']!);
                                    },
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    softWrap: true,
                                    server['ip'] ?? '',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    _pingResults[ip] ?? '---',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Espacio entre las tablas
            const SizedBox(width: 22),
            // Tabla de Dispositivos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Dispositivos',
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    // Usar Expanded para ajustarse al espacio disponible
                    child: Table(
                      border: TableBorder.all(),
                      columnWidths: const <int, TableColumnWidth>{
                        0: FlexColumnWidth(2), // Campo de Nombre más ancho
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(0.8),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('NOMBRE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('IP',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('MS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22)),
                            ),
                          ],
                        ),
                        ...widget.servers
                            .where((server) => server['tipo'] == 'dispositivo')
                            .map((server) {
                          final ip = server['ip'];
                          return TableRow(
                            children: [
                              Row(
                                children: [
                                  // Indicador de estado
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _serverStatus[ip] == 'Online'
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                  ),
                                  // Nombre del servidor
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        server['nombre'] ?? '',
                                        style: const TextStyle(fontSize: 22),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  // Boton de editar
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      widget.onEditServer(server['id']!);
                                    },
                                  ),
                                  // Boton de eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      widget.onRemoveServer(server['id']!);
                                    },
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    ip ?? '',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    _pingResults[ip] ?? '',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
