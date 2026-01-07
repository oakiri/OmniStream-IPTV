import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/epg_program.dart';

abstract class EpgRemoteDataSource {
  Future<List<EpgProgram>> getEpgData(String url);
}

class EpgRemoteDataSourceImpl implements EpgRemoteDataSource {
  final Dio dio;

  EpgRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<EpgProgram>> getEpgData(String url) async {
    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.data);
        final programs = <EpgProgram>[];

        final programmeElements = document.findAllElements('programme');

        for (final element in programmeElements) {
          final channelId = element.getAttribute('channel');
          final startStr = element.getAttribute('start');
          final stopStr = element.getAttribute('stop');
          final title = element.findElements('title').first.text;
          final desc = element.findElements('desc').firstOrNull?.text;

          if (channelId != null && startStr != null && stopStr != null) {
            programs.add(
              EpgProgram(
                channelId: channelId,
                start: _parseEpgDate(startStr),
                stop: _parseEpgDate(stopStr),
                title: title,
                desc: desc,
              ),
            );
          }
        }
        return programs;
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }

  DateTime _parseEpgDate(String dateStr) {
    // Format is typically '20231027180000 +0000'
    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));
    final hour = int.parse(dateStr.substring(8, 10));
    final minute = int.parse(dateStr.substring(10, 12));
    final second = int.parse(dateStr.substring(12, 14));

    // Handle timezone offset if present
    final tzOffset = dateStr.contains(' ') ? dateStr.split(' ')[1] : '+0000';
    final offsetSign = tzOffset.startsWith('-') ? -1 : 1;
    final offsetHours = int.parse(tzOffset.substring(1, 3));
    final offsetMinutes = int.parse(tzOffset.substring(3, 5));
    final offsetDuration = Duration(hours: offsetHours, minutes: offsetMinutes);

    final utcTime = DateTime.utc(year, month, day, hour, minute, second);
    
    if (offsetSign == 1) {
        return utcTime.subtract(offsetDuration);
    } else {
        return utcTime.add(offsetDuration);
    }
  }
}
