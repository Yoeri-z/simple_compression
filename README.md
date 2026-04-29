A minimal Dart wrapper for FFmpeg that simplifies compression into some easily understandable parameters.

## Usage

Initialize the compressor with your chosen constraints. The `compress` method returns a `CompressionTask` used to track progress or await completion.

### Example
```dart
void main() async {
  final compressor = SimpleCompressor(
    constraints: VideoConstraints(maxFileSizeMb: 10, maxWidth: 720),
  );

  final task = compressor.compress(
    input: File('input.mp4'),
    outputPath: 'output.mp4',
  );

  // Listen to real-time progress (0.0 to 1.0)
  task.progress.listen((p) => print('Progress: ${p * 100}%'));

  // Or simply await completion
  await task.onComplete;
  print('Compression finished.');
}
```

## Media Constraints

You can swap the compressor's behavior by passing different constraint objects to the constructor:

* **VideoConstraints**: Set `maxFileSizeMb` (per minute) and `maxWidth`. Height is automatically adjusted to an even number.
* **AudioConstraints**: Set `maxFileSizeMb` (per minute) and optional `forceMono`.
* **ImageConstraints**: Set `maxFileSizeMb` (total target) and `maxWidth`.

## Configuration

### SimpleCompressor
| Parameter | Type | Description |
| :--- | :--- | :--- |
| `constraints` | `MediaConstraints` | The settings for the task (Video, Audio, or Image). |
| `ffmpegPath` | `String?` | Path to FFmpeg. Defaults to `ffmpeg` in system PATH. |

### CompressionTask (Return Object)
| Property | Type | Description |
| :--- | :--- | :--- |
| `progress` | `Stream<double>` | A stream of the current progress (0.0 to 1.0). |
| `onComplete` | `Future<void>` | A future that resolves when the compression finishes. |

## Requirements
Requires `ffmpeg`to be available in your system PATH or provided to simple compressor through `ffmpegPath`. If you are using this it is recommended to bundle a static binary with some built in video codecs, some good sources for these have been summarized in the table below.

| OS | Source | Recommended Build |
| :--- | :--- | :--- |
| **Windows** | [Gyan.dev](https://www.gyan.dev/ffmpeg/builds/) | `ffmpeg-release-essentials.zip` |
| **Linux** | [John Van Sickle](https://johnvansickle.com/ffmpeg/) | `ffmpeg-release-amd64-static.tar.xz` |
| **macOS** | [Evermeet.cx](https://evermeet.cx/ffmpeg/) | `ffmpeg`|


## License
MIT