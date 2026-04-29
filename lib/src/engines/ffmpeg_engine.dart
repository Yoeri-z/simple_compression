import 'dart:convert';
import 'dart:io';

import 'package:simple_compression/src/engines/compression_engine.dart';
import 'package:simple_compression/src/media_constraints.dart';

enum MediaType { video, audio, image, unknown }

class FileDetails {
  final MediaType type;
  final String format;
  final Duration? duration;
  final int? width;
  final int? height;
  final int sizeInBytes;

  FileDetails({
    required this.type,
    required this.format,
    this.duration,
    this.width,
    this.height,
    required this.sizeInBytes,
  });

  bool get isVisual => type == MediaType.video || type == MediaType.image;
}

class FFmpegEngine implements CompressionEngine {
  FFmpegEngine(this.ffmpegPath);

  final String ffmpegPath;

  List<String> _videoArgs(File input, String output, VideoConstraints v) {
    String? bitrate;
    if (v.maxFileSizeMb != null) {
      // Logic: (MB * 8192) / 60 seconds = kbps
      final kbps = (v.maxFileSizeMb! * 8192) / 60;
      bitrate = '${kbps.toInt()}k';
    }

    return [
      '-y',
      '-i',
      input.path,
      if (v.maxWidth != null) ...['-vf', 'scale=${v.maxWidth}:-2'],
      if (bitrate != null) ...[
        '-b:v',
        bitrate,
        '-maxrate',
        bitrate,
        '-bufsize',
        '2M',
      ],
      '-preset',
      v.speed,
      output,
    ];
  }

  List<String> _audioArgs(File input, String output, AudioConstraints a) {
    String? bitrate;
    if (a.maxFileSizeMb != null) {
      // Logic: (MB * 8192) / 60 seconds = kbps
      final kbps = (a.maxFileSizeMb! * 8192) / 60;
      bitrate = '${kbps.toInt()}k';
    }

    return [
      '-y',
      '-i',
      input.path,
      if (bitrate != null) ...['-b:a', bitrate],
      if (a.forceMono) ...['-ac', '1'],
      output,
    ];
  }

  List<String> _imageArgs(File input, String output, ImageConstraints i) {
    return [
      '-y', '-i', input.path,
      if (i.maxWidth != null) ...['-vf', 'scale=${i.maxWidth}:-2'],
      // For images, FFmpeg uses -size or quality mapping.
      // Easiest is using target size if the encoder supports it,
      // or a simple quality fallback.
      output,
    ];
  }

  List<String> _buildArgs(File input, String output, MediaConstraints c) {
    return switch (c) {
      VideoConstraints v => _videoArgs(input, output, v),
      AudioConstraints a => _audioArgs(input, output, a),
      ImageConstraints i => _imageArgs(input, output, i),
    };
  }

  Duration? _parseTotalDuration(String line) {
    final match = RegExp(
      r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})',
    ).firstMatch(line);
    if (match == null) return null;

    return Duration(
      hours: int.parse(match.group(1)!),
      minutes: int.parse(match.group(2)!),
      seconds: int.parse(match.group(3)!),
      milliseconds: int.parse(match.group(4)!) * 10,
    );
  }

  Duration? _parseTime(String line) {
    final match = RegExp(
      r'time=(\d{2}):(\d{2}):(\d{2})\.(\d{2})',
    ).firstMatch(line);
    if (match == null) return null;

    return Duration(
      hours: int.parse(match.group(1)!),
      minutes: int.parse(match.group(2)!),
      seconds: int.parse(match.group(3)!),
      milliseconds: int.parse(match.group(4)!) * 10,
    );
  }

  @override
  Stream<double> compress({
    required File input,
    required String outputPath,
    required MediaConstraints constraints,
  }) async* {
    yield 0.0;

    Duration? totalDuration;

    final args = _buildArgs(input, outputPath, constraints);

    final process = await Process.start(ffmpegPath, args);
    final errorLog = <String>[];

    final stderrStream = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stderrStream) {
      if (errorLog.length > 30) errorLog.removeAt(0);
      errorLog.add(line);

      totalDuration ??= _parseTotalDuration(line);

      final currentTime = _parseTime(line);

      if (totalDuration != null && currentTime != null) {
        final progress =
            currentTime.inMicroseconds / totalDuration.inMicroseconds;
        yield progress.clamp(0.0, 0.99);
      }
    }

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception(
        'FFmpeg failed (exit $exitCode).\n'
        'Last logs:\n${errorLog.join('\n')}',
      );
    }

    yield 1.0;
  }
}
