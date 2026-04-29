import 'dart:io';

import 'package:path/path.dart' as p;

enum MediaType { image, video, audio, unknown }

extension GetFormat on File {
  MediaFormat get getFormat {
    final ext = p.extension(path).toLowerCase();
    // Return a known format or generate a generic one on the fly
    return MediaFormat.lookup[ext] ?? MediaFormat.generic(ext);
  }
}

class MediaFormat {
  const MediaFormat(this.extension, this.type);

  MediaFormat.generic(String extension) : this(extension, .unknown);

  final String extension;
  final MediaType type;

  static const MediaFormat png = MediaFormat('png', MediaType.image);
  static const MediaFormat jpg = MediaFormat('jpg', MediaType.image);
  static const MediaFormat webp = MediaFormat('webp', MediaType.image);
  static const MediaFormat gif = MediaFormat('gif', MediaType.image);

  static const MediaFormat mp4 = MediaFormat('mp4', MediaType.video);
  static const MediaFormat mov = MediaFormat('mov', MediaType.video);
  static const MediaFormat avi = MediaFormat('avi', MediaType.video);
  static const MediaFormat webm = MediaFormat('webm', MediaType.video);
  static const MediaFormat mkv = MediaFormat('mkv', MediaType.video);

  static const MediaFormat mp3 = MediaFormat('mp3', MediaType.audio);
  static const MediaFormat wav = MediaFormat('wav', MediaType.audio);
  static const MediaFormat m4a = MediaFormat('m4a', MediaType.audio);
  static const MediaFormat flac = MediaFormat('flac', MediaType.audio);
  static const MediaFormat ogg = MediaFormat('ogg', MediaType.audio);

  static const Map<String, MediaFormat> lookup = {
    '.png': png,
    '.jpg': jpg,
    '.jpeg': jpg,
    '.webp': webp,
    '.gif': gif,
    '.mp4': mp4,
    '.mov': mov,
    '.avi': avi,
    '.webm': webm,
    '.mkv': mkv,
    '.mp3': mp3,
    '.wav': wav,
    '.m4a': m4a,
    '.flac': flac,
    '.ogg': ogg,
  };
}
