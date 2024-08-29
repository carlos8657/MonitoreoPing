import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ServerManager {
  List<Map<String, String>> _servers = [];

  List<Map<String, String>> get servers => _servers;

  // Cargar datos desde el archivo JSON
  Future<void> loadServers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final monitorDirectory = Directory('${directory.path}/monitoreo_ip');
      if (!await monitorDirectory.exists()) {
        await monitorDirectory.create(recursive: true);
      }
      final filePath = '${monitorDirectory.path}/servers.json';
      final file = File(filePath);

      if (await file.exists()) {
        final fileContent = await file.readAsString();
        final List<dynamic> jsonData = json.decode(fileContent);
        _servers = jsonData.map<Map<String, String>>((server) {
          return {
            'nombre': server['nombre'].toString(),
            'ip': server['ip'].toString(),
          };
        }).toList();
      }
    } catch (e) {
      print('Error loading servers: $e');
    }
  }

  // Guardar los datos en el archivo JSON
  Future<void> saveServers() async {
    final directory = await getApplicationDocumentsDirectory();
    final monitorsDir = Directory('${directory.path}/monitoreo_ip');

    // Crear el directorio si no existe
    if (!await monitorsDir.exists()) {
      await monitorsDir.create(recursive: true);
    }

    final filePath = '${monitorsDir.path}/servers.json';
    final file = File(filePath);

    await file.writeAsString(json.encode(_servers));
  }

  // Agregar un nuevo servidor
  void addServer(Map<String, String> server) {
    _servers.add(server);
  }

  // Eliminar un servidor por nombre o IP
  void removeServer(String value) {
    _servers.removeWhere((server) => server['ip'] == value);
    saveServers(); // Guarda automáticamente después de eliminar
  }
}
