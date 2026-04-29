import 'dart:io';

import 'package:simple_compression/src/media_constraints.dart';

export 'ffmpeg_engine.dart';

abstract class CompressionEngine {
  Stream<double> compress({
    required File input,
    required String outputPath,
    required MediaConstraints constraints,
  });
}
