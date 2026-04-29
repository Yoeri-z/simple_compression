import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:simple_compression/src/compression_config.dart';
import 'package:simple_compression/src/file_format.dart';
import 'package:simple_compression/src/providers/compression_provider.dart';

class FFmpegConfig extends CompressionConfig {
  const FFmpegConfig({
    this.width,
    this.height,
    this.preset = 'medium',
    this.crf = 23,
    this.threads = 0,
    this.videoCodec = 'libx264',
    this.audioCodec = 'aac',
    this.videoBitrate,
    this.audioBitrate = '128k',
    this.fps,
    this.sampleRate,
    this.forceMono = false,
    this.customArgs = const [],
  });

  final int? width;
  final int? height;
  final String preset;
  final int crf;
  final int threads;
  final String videoCodec;
  final String audioCodec;

  final String? videoBitrate;
  final String audioBitrate;
  final int? fps;
  final int? sampleRate;
  final bool forceMono;

  /// Inject ffmpeg specific flags that are not present in this config.
  final List<String> customArgs;
}

class FFmpegProvider implements CompressionProvider<FFmpegConfig> {
  FFmpegProvider({this.binaryPath});

  final String? binaryPath;

  @override
  String get name => 'FFmpeg';

  @override
  bool isFormatSupported(MediaFormat format) {
    return format.type == .image ||
        format.type == .video ||
        format.type == .audio ||
        format.type == .unknown;
  }

  @override
  Stream<double> compress({
    required File file,
    required FFmpegConfig config,
    required String outputPath,
  }) async* {
    final args = _buildArgs(file.path, outputPath, config);
    final process = await Process.start(binaryPath ?? 'ffmpeg', args);

    // Buffer to store logs for error reporting
    final errorLog = <String>[];

    final stderrStream = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    Duration? totalDuration;

    await for (final line in stderrStream) {
      // Keep a rolling buffer of the last 20 lines to keep exception messages readable
      if (errorLog.length > 20) errorLog.removeAt(0);
      errorLog.add(line);

      totalDuration ??= _parseDuration(line, 'Duration: ');
      final currentTime = _parseDuration(line, 'time=');

      if (totalDuration != null && currentTime != null) {
        final progress =
            currentTime.inMicroseconds / totalDuration.inMicroseconds;
        yield progress.clamp(0.0, 1.0);
      }
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      // Construct a detailed error message
      final message = errorLog.join('\n');
      throw Exception(
        'FFmpeg failed (exit $exitCode).\n'
        '--- FFmpeg stderr ---\n'
        '$message\n'
        '----------------------',
      );
    }

    yield 1.0;
  }

  List<String> _buildArgs(String input, String output, FFmpegConfig config) {
    String? scaleFilter;
    if (config.width != null || config.height != null) {
      final w = config.width ?? -1;
      final h = config.height ?? -1;
      scaleFilter = 'scale=$w:$h';
    }

    return [
      '-y',
      '-threads', '${config.threads}',
      '-i', input,
      if (scaleFilter != null) ...['-vf', scaleFilter],
      // Video/image Settings
      '-vcodec', config.videoCodec,
      if (config.videoBitrate != null) ...['-b:v', config.videoBitrate!],
      if (config.videoCodec.contains('x264') ||
          config.videoCodec.contains('x265')) ...[
        '-crf',
        '${config.crf}',
      ],
      '-preset', config.preset,
      if (config.fps != null) ...['-r', '${config.fps}'],

      // Audio Settings
      '-acodec', config.audioCodec,
      '-b:a', config.audioBitrate,
      if (config.sampleRate != null) ...['-ar', '${config.sampleRate}'],
      if (config.forceMono) ...['-ac', '1'],

      ...config.customArgs,

      output,
    ];
  }

  Duration? _parseDuration(String line, String prefix) {
    final match = RegExp(
      '$prefix\\s*(\\d+):(\\d{2}):(\\d{2}\\.\\d+)',
    ).firstMatch(line); //regex for matching x0:00:00.00x formats

    if (match == null) return null;

    return Duration(
      hours: int.parse(match.group(1)!),
      minutes: int.parse(match.group(2)!),
      milliseconds: (double.parse(match.group(3)!) * 1000).toInt(),
    );
  }
}
