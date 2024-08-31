import 'dart:convert';
import 'dart:io';

class PingService {
  Future<Map<String, String>> pingHost(String host) async {
    String dataGuardar = '';

    try {
      final process = await Process.start(
        'ping',
        [host],
        mode: ProcessStartMode.normal,
      );

      process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((data) {
        dataGuardar += data;
      });

      await process.exitCode;
      return extractIpAndAvgTime(dataGuardar);
    } catch (e) {
      return {'ip': host, 'media': 'Error'};
    }
  }

  Map<String, String> extractIpAndAvgTime(String pingOutput) {
    // print(pingOutput);
    // Buscar la IP en la salida del ping
    final ipPattern =
        RegExp(r'\[(\d+\.\d+\.\d+\.\d+)\]|\b(\d+\.\d+\.\d+\.\d+)\b');
    final ipMatch = ipPattern.firstMatch(pingOutput);
    final ip = ipMatch?.group(1) ?? ipMatch?.group(2) ?? 'IP no encontrada';

    // Buscar la cantidad de paquetes perdidos
    final lostPacketsPattern = RegExp(r'perdidos\s+=\s+(\d+)');
    final lostPacketsMatch = lostPacketsPattern.firstMatch(pingOutput);
    final lostPackets = int.tryParse(lostPacketsMatch?.group(1) ?? '0');
    // Si se perdieron todos los paquetes, devolvemos que el ping falló
    if (lostPackets == 5) {
      return {'ip': ip, 'media': 'Ping fallido'};
    }

    // Buscar el primer tiempo de respuesta (ms)
    final timePattern = RegExp(r'tiempo[=<]\s*(\d+)ms');
    final firstMatch = timePattern.firstMatch(pingOutput);

    // Buscar el tiempo de respuesta promedio (ms)
    final avgPattern = RegExp(r'Media\s+=\s*(\d+)ms');
    final avgMatch = avgPattern.firstMatch(pingOutput);

    // Si se encuentra un tiempo, devolverlo
    if (firstMatch != null) {
      final time = firstMatch.group(1);
      return {'ip': ip, 'media': '${time}ms'};
    } else if (avgMatch != null) {
      final avgTime = avgMatch.group(1);
      return {'ip': ip, 'media': '${avgTime}ms'};
    }

    // Si no se encuentra ningún tiempo, devolvemos un ping fallido
    return {'ip': ip, 'media': 'Ping fallido'};
  }
}
