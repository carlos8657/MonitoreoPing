import 'dart:convert';
import 'dart:io';

class PingService {
  Future<Map<String, String>> pingHost(String host) async {
    String dataGuardar = '';

    try {
      final process = await Process.start(
        'ping',
        ['-n','1',host],
        mode: ProcessStartMode.normal,
      );

      process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((data) {
        dataGuardar += data;
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        print('Error: $data');
      });

      final exitCode = await process.exitCode;
      print('Process exited with code: $exitCode');
      return extractIpAndAvgTime(dataGuardar);
    } catch (e) {
      print('Failed to run ping: $e');
      return {'ip': host, 'media': 'Error'};
    }
  }

  Map<String, String> extractIpAndAvgTime(String pingOutput) {
    final ipPattern =
        RegExp(r'\[(\d+\.\d+\.\d+\.\d+)\]|\b(\d+\.\d+\.\d+\.\d+)\b');
    final ipMatch = ipPattern.firstMatch(pingOutput);
    final ip = ipMatch?.group(1) ?? ipMatch?.group(2) ?? 'IP no encontrada';

    final lostPacketsPattern = RegExp(r'perdidos\s+=\s+(\d+)');
    final lostPacketsMatch = lostPacketsPattern.firstMatch(pingOutput);
    final lostPackets = int.tryParse(lostPacketsMatch?.group(1) ?? '0');

    if (lostPackets == 4 || lostPackets == 3  ) {
      return {'ip': ip, 'media': 'Ping fallido'};
    }
    final avgPattern = RegExp(r'Media\s+=\s+(\d+)ms');
    final avgMatch = avgPattern.firstMatch(pingOutput);
    final avgTime = avgMatch?.group(1) ?? 'Media no encontrada';
    if(avgTime == 'Media no encontrada'){
      return {'ip': ip, 'media': 'Ping fallido'};
    }

    return {'ip': ip, 'media': '${avgTime}ms'};
  }
}
