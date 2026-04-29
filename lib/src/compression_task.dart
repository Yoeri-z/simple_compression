import 'dart:async';
import 'dart:io';

import 'package:simple_compression/src/compression_config.dart';
import 'package:simple_compression/src/file_format.dart';
import 'package:simple_compression/src/providers/compression_provider.dart';

enum CompressionStatus { initial, compressing, completed, error }

class CompressionTask<T extends CompressionConfig> {
  CompressionTask({
    required this.sourceFile,
    required this.provider,
    required this.config,
  });

  /// The file to be compressed.
  final File sourceFile;

  /// The provider that handles the compressions
  ///
  /// Currently available providers are:
  ///
  /// You can make your own provider by implementing [CompressionProvider]
  final CompressionProvider<T> provider;

  /// The configuration dictating the manner in which this file is compressed.
  final T config;

  final Completer<File> _completer = Completer<File>();

  CompressionStatus _status = CompressionStatus.initial;
  double _progress = 0.0;
  late final Stream<double> _broadcast;
  File? _result;

  Future<File> get result => _completer.future;

  CompressionStatus get status => _status;
  double get progress => _progress;
  Stream<double> get progressStream => _broadcast;

  /// Starts the compression process.
  ///
  /// This function returns immediately after starting.
  /// Use [result] to wait for the final result.
  void start(String outputPath) async {
    if (_status != CompressionStatus.initial) return;

    _status = CompressionStatus.compressing;

    try {
      final format = sourceFile.getFormat;
      if (!provider.isFormatSupported(format)) {
        throw UnsupportedError(
          "Provider ${provider.name} does not support this format.",
        );
      }

      final stream = provider.compress(
        file: sourceFile,
        config: config,
        outputPath: outputPath,
      );

      _broadcast = stream.asBroadcastStream();

      await for (final p in _broadcast) {
        _progress = p;
      }

      _result = File(outputPath);
      _status = CompressionStatus.completed;

      // Resolve the completer
      _completer.complete(_result);
    } catch (e, st) {
      _status = CompressionStatus.error;

      _completer.completeError(e, st);
    }
  }
}
