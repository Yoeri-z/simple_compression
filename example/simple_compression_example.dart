import 'dart:io';

import 'package:simple_compression/simple_compression.dart';

// For this example to work without making any changes
// ffmpeg should be available on path.
void main() async {
  final compressor = SimpleCompressor(
    constraints: VideoConstraints(maxFileSizeMb: 10, maxWidth: 720),
  );

  final task = compressor.compress(
    input: File('assets/cute_cat_video.mp4'),
    outputPath: 'out/compressed_cat_video.mp4',
  );

  print('Starting compression');

  await for (final percentage in task.progress) {
    print('Progress: ${percentage * 100}');
  }

  print('Finished compression');
}
