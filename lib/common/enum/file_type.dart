enum FileType {
  video,
  image,
  unknown;

  bool get isVideo {
    return this == video;
  }

  bool get isPhoto=>this == image;
}
