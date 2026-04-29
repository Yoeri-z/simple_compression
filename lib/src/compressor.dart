import 'dart:io';

import 'package:simple_compression/simple_compression.dart';

class CompressionTask {
  CompressionTask._(this._stream);

  final Stream<double> _stream;

  /// A stream of the compression progress (0.0 to 1.0).
  Stream<double> get progress => _stream;

  /// A convenience future that completes when the stream hits 1.0.
  Future<void> get onComplete => _stream.last;
}

class SimpleCompressor {
  SimpleCompressor({required this.constraints, this.ffmpegPath = 'ffmpeg'})
    : _engine = FFmpegEngine(ffmpegPath);

  final MediaConstraints constraints;
  final String ffmpegPath;
  final CompressionEngine _engine;

  /// Starts a compression task.
  /// Returns a [CompressionTask] which holds the progress stream and final result.
  CompressionTask compress({required File input, required String outputPath}) {
    return CompressionTask._(
      _engine.compress(
        input: input,
        outputPath: outputPath,
        constraints: constraints,
      ),
    );
  }
}
