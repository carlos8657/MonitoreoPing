import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:monitoreo_ip/services/ping.dart';
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
  final Map<String, int> numeroAlertas = {};
  final Map<String, int> pingFallidos = {};

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
    Timer.periodic(const Duration(seconds: 1), (timer) {
      for (var server in widget.servers) {
        final ip = server['ip'];
        if (ip != null) {
          _pingService.pingHost(ip).then((result) {
            if (result['media'] == 'Ping fallido' ||
                result['media'] == 'Error') {
              pingFallidos[ip] = (pingFallidos[ip] ?? 0) + 1;
            } else {
              pingFallidos[ip] = 0;
              server['excluir'] = 'false';
            }
            final isError = (result['media'] == 'Ping fallido' ||
                result['media'] == 'Error');

            setState(() {
              _pingResults[ip] = result['media'] ?? 'Error';
              _serverStatus[ip] = isError ? 'Offline' : 'Online';
            });

            // Muestra la alerta solo si el servidor no está excluido y es un error
            if (!_isAlertVisible &&
                isError &&
                pingFallidos[ip]! >= 60 &&
                server['excluir'] != 'true') {
              restoreWindow();
              _showErrorAlert(ip, result['media']!, server['nombre']!);

              numeroAlertas[ip] = (numeroAlertas[ip] ?? 0) + 1;
              if (numeroAlertas[ip]! >= 3) {
                numeroAlertas[ip] = 0;
                server['excluir'] = 'true';
              }
            }
          });
        }
      }
    });
  }

  void _showErrorAlert(String ip, String error, String server) {
    if (_isAlertVisible) return; // Evitar mostrar múltiples alertas

    if (widget.isAudioEnabled) {
      _player.play(AssetSource('alerta.mp3'));
    }

    setState(() {
      _isAlertVisible = true;
    });

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
                    Text(
                      'Servidor: $server\nIP: $ip\nError: $error',
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16.0),
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
      child: SingleChildScrollView(
        child: Table(
          border: TableBorder.all(color: const Color.fromARGB(255, 0, 83, 226)),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color.fromARGB(255, 0, 83, 226)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Dispositivo',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'IP',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Latencia',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ...widget.servers.map(
              (server) => TableRow(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 130,
                          child: Center(
                            child: Text(
                              server['nombre'] ?? '',
                              style: const TextStyle(fontSize: 25),
                              softWrap: true,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Editar servidor
                          widget.onEditServer(server['ip'] ?? '');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          widget.onRemoveServer(server['ip'] ?? '');
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 130,
                    child: Container(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(server['ip'] ?? '',
                              style: const TextStyle(fontSize: 25)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 130,
                    child: Container(
                      color: _pingResults[server['ip']] == 'Error' ||
                              _pingResults[server['ip']] == 'Ping fallido' ||
                              _pingResults[server['ip']] == null
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Text(
                          _pingResults[server['ip']] == 'Error' ||
                                  _pingResults[server['ip']] ==
                                      'Ping fallido' ||
                                  _pingResults[server['ip']] == null
                              ? 'Offline'
                              : 'Online',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 130,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(_pingResults[server['ip']] ?? '---',
                            style: const TextStyle(fontSize: 25)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
