import 'dart:async';
import 'dart:io';
import 'package:simple_compression/simple_compression.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockCompressionConfig extends Mock implements CompressionConfig {}

class MockCompressionProvider extends Mock
    implements CompressionProvider<MockCompressionConfig> {}

class MockFile extends Mock implements File {}

void mockProviderName(MockCompressionProvider provider) {
  when(() => provider.name).thenReturn('Mock provider');
}

void mockFilePath(MockFile sourceFile) {
  when(() => sourceFile.path).thenReturn('video.mp4');
}

void mockFormatAlwaysSupported(MockCompressionProvider provider) =>
    when(() => provider.isFormatSupported(any())).thenReturn(true);

void mockCompressionProgress({
  required MockCompressionProvider provider,
  required StreamController<double> controller,
  required File file,
  required MockCompressionConfig config,
}) {
  return when(
    () => provider.compress(
      file: file,
      config: config,
      outputPath: any(named: 'outputPath'),
    ),
  ).thenAnswer((_) => controller.stream);
}

void main() {
  group('CompressionTask', () {
    late MockCompressionProvider provider;
    late MockFile sourceFile;
    late MockCompressionConfig config;
    const outputPath = 'output.mp4';

    setUp(() {
      provider = MockCompressionProvider();
      sourceFile = MockFile();
      config = MockCompressionConfig();

      registerFallbackValue(MediaFormat.mp4);
      mockFilePath(sourceFile);
      mockProviderName(provider);
      mockFormatAlwaysSupported(provider);
    });

    test('should resolve result future on successful compression', () async {
      final controller = StreamController<double>();
      mockCompressionProgress(
        provider: provider,
        controller: controller,
        file: sourceFile,
        config: config,
      );

      final task = CompressionTask(
        sourceFile: sourceFile,
        provider: provider,
        config: config,
      );

      task.start(outputPath);

      // Simulate progress
      controller.add(0.5);
      controller.add(1.0);
      controller.close();

      final file = await task.result;

      expect(task.status, CompressionStatus.completed);
      expect(file.path, outputPath);
      expect(task.progress, 1.0);
    });
    test('should report error through the result future', () async {
      final controller = StreamController<double>();

      mockCompressionProgress(
        provider: provider,
        controller: controller,
        file: sourceFile,
        config: config,
      );

      final task = CompressionTask(
        sourceFile: sourceFile,
        provider: provider,
        config: config,
      );

      task.start(outputPath);
      controller.addError(Exception('Mock provider failure'));

      expect(task.result, throwsA(isA<Exception>()));

      // Wait for catch block to finish
      try {
        await task.result;
      } catch (_) {}
      expect(task.status, CompressionStatus.error);
    });

    test('progressStream should allow multiple listeners', () async {
      final controller = StreamController<double>();
      mockCompressionProgress(
        provider: provider,
        controller: controller,
        file: sourceFile,
        config: config,
      );

      final task = CompressionTask(
        sourceFile: sourceFile,
        provider: provider,
        config: config,
      );

      task.start(outputPath);

      // Verify broadcast capability
      final firstListener = task.progressStream.toList();
      final secondListener = task.progressStream.toList();

      controller.add(0.2);
      controller.add(0.8);
      await controller.close();

      final results = await Future.wait([firstListener, secondListener]);

      expect(results[0], [0.2, 0.8]);
      expect(results[1], [0.2, 0.8]);
    });
  });
}
