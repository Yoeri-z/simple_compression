A flexible, type-safe, and provider agnostic media compression library for Dart and Flutter. 

Unlike other compression wrappers, `simple_compression` uses a **Provider architecture**, allowing you to swap between different compression engines (like FFmpeg, Native APIs, or Cloud services) while maintaining a consistent API.

## Features

* **Compression tasks:** A dev friendly api that helps you manage the state and progress of compression over its duration.
* **Compression provider** An interface that can be implemented to create custom compression handlers
* **Configurations:** Providers define their own configuration requirements (e.g., `FFmpegConfig` for `FFmpegProvider`).
* **FFMpeg:** This package comes with an implementation to use ffmpeg for compressing various audio-visual formats.

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  simple_compression: ^1.0.0
```

## Usage

### 1. Initialize a Provider
Currently, the package supports `FFmpegProvider`. You just need the path to your FFmpeg binary.

```dart
import 'package:simple_compression/simple_compression.dart';

final ffmpeg = FFmpegProvider(binaryPath: '/assets/bin/ffmpeg');
```

### 2. Configure the Compression
Configurations are specific to the provider to ensure you have access to all the engine's unique features.

```dart
final config = FFmpegConfig(
  width: 1280,            // Rescale to 720p (aspect ratio preserved)
  crf: 28,                // Quality setting (0-51)
  preset: 'faster',       // Encoding speed
  forceMono: true,        // Convert audio to mono
);
```

### 3. Do a compression
The `CompressionTask` manages the lifecycle. You can start it and `await` the result later.

```dart
final task = CompressionTask(
  sourceFile: File('input.mp4'),
  provider: ffmpeg,
  config: config,
);

// Start the process
task.start('/path/to/output.mp4');

// Listen to progress
task.progressStream.listen((p) => print('Progress: ${p * 100}%'));

// Await the final file
try {
  File result = await task.result;
  print('Saved to: ${result.path}');
} catch (e) {
  print('Compression failed: $e');
}
```
## Custom Providers

You can implement your own provider by extending the base class:

```dart
class MyCustomProvider implements CompressionProvider<MyConfig> {
  @override
  Stream<double> compress(File file, MyConfig config, String ouputPath) async* {
    // Implement your logic here
  }
  
  @override
  bool isFormatSupported(MediaFormat format) => true;
  
  @override
  String get name => 'CustomProvider';
}
```

## Troubleshooting FFmpeg on Linux (Fedora)

If you encounter `Unknown encoder 'libx264'`, ensure you have the full FFmpeg version installed rather than the "free" version provided by default repositories.

```bash
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.