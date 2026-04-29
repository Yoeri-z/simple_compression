import 'dart:io';

import 'package:simple_compression/src/compression_config.dart';
import 'package:simple_compression/src/file_format.dart';

export 'ffmpeg.dart';

/// Interface for compression.
///
/// A [CompressionTask] needs a provider to do a compression.
///
/// This package provides an implementation for ffmpeg through [FFmpegProvider]
abstract class CompressionProvider<T extends CompressionConfig> {
  String get name;

  bool isFormatSupported(MediaFormat format);

  Stream<double> compress({
    required File file,
    required T config,
    required String outputPath,
  });
}
