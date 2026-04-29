sealed class MediaConstraints {
  int? get maxFileSizeMb;
}

class VideoConstraints extends MediaConstraints {
  VideoConstraints({this.maxWidth, this.maxFileSizeMb, this.speed = 'medium'});

  final int? maxWidth;

  /// The maximum file size per minute of video
  @override
  final int? maxFileSizeMb;
  final String speed;
}

class AudioConstraints extends MediaConstraints {
  AudioConstraints({this.maxFileSizeMb, this.forceMono = false});

  /// The maximum file size per minute of audio
  @override
  final int? maxFileSizeMb;
  final bool forceMono;
}

class ImageConstraints extends MediaConstraints {
  ImageConstraints({this.maxFileSizeMb, this.maxWidth});

  /// The maximum file size of the final image
  @override
  final int? maxFileSizeMb;
  final int? maxWidth;
}
