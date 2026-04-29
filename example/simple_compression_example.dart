import 'dart:io';

import 'package:simple_compression/simple_compression.dart';

// For this example to work without making any changes
// ffmpeg should be available on path.
void main() async {
  final video = File('assets/cute_cat_video.mp4');

  final task = CompressionTask(
    sourceFile: video,
    provider: FFmpegProvider(),
    config: FFmpegConfig(videoBitrate: '1M', videoCodec: 'libopenh264'),
  );

  task.start('out/compressed_cat_video.mp4');
  task.progressStream.listen(
    (progress) => print('Current progress: ${progress * 100}%'),
  );

  try {
    final result = await task.result;
    print('Outputted compressed video at: ${result.absolute.path}');
  } catch (_) {
    print('Compression task failed :(');
  }
}
