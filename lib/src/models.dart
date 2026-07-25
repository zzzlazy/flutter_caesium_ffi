import 'dart:typed_data';

/// Supported encoded image formats.
enum CaesiumFormat {
  /// JPEG.
  jpeg(0),

  /// PNG.
  png(1),

  /// GIF.
  gif(2),

  /// WebP.
  webp(3),

  /// TIFF.
  tiff(4);

  const CaesiumFormat(this.nativeValue);

  /// Value used by the native ABI.
  final int nativeValue;
}

/// JPEG chroma subsampling.
enum JpegChromaSubsampling {
  /// Let libcaesium select the mode.
  auto(0),

  /// 4:4:4.
  cs444(444),

  /// 4:2:2.
  cs422(422),

  /// 4:2:0.
  cs420(420),

  /// 4:1:1.
  cs411(411);

  const JpegChromaSubsampling(this.nativeValue);

  /// Value used by the native ABI.
  final int nativeValue;
}

/// TIFF compression algorithms.
enum TiffCompression {
  /// Store pixels without compression.
  uncompressed(0),

  /// LZW.
  lzw(1),

  /// Deflate.
  deflate(2),

  /// PackBits.
  packBits(3);

  const TiffCompression(this.nativeValue);

  /// Value used by the native ABI.
  final int nativeValue;
}

/// TIFF Deflate compression levels.
enum TiffDeflateLevel {
  /// Fastest compression.
  fast(1),

  /// Balanced compression.
  balanced(6),

  /// Smallest output.
  best(9);

  const TiffDeflateLevel(this.nativeValue);

  /// Value used by the native ABI.
  final int nativeValue;
}

/// JPEG-specific settings.
final class JpegOptions {
  /// Creates JPEG settings matching libcaesium defaults.
  const JpegOptions({
    this.quality = 80,
    this.chromaSubsampling = JpegChromaSubsampling.auto,
    this.progressive = true,
    this.optimize = false,
    this.preserveIcc = true,
  });

  /// Lossy quality from 0 to 100.
  final int quality;

  /// Chroma subsampling mode.
  final JpegChromaSubsampling chromaSubsampling;

  /// Whether to write a progressive JPEG.
  final bool progressive;

  /// Whether to perform lossless JPEG optimization.
  final bool optimize;

  /// Whether to preserve the ICC profile independently of metadata.
  final bool preserveIcc;

  void validate() => _validateQuality('jpeg.quality', quality);
}

/// PNG-specific settings.
final class PngOptions {
  /// Creates PNG settings matching libcaesium defaults.
  const PngOptions({
    this.quality = 80,
    this.optimizationLevel = 3,
    this.forceZopfli = false,
    this.optimize = false,
  });

  /// Lossy palette quality from 0 to 100.
  final int quality;

  /// Optimization level from 0 to 6.
  final int optimizationLevel;

  /// Whether to force the slower Zopfli compressor.
  final bool forceZopfli;

  /// Whether to use lossless PNG optimization.
  final bool optimize;

  void validate() {
    _validateQuality('png.quality', quality);
    if (optimizationLevel < 0 || optimizationLevel > 6) {
      throw RangeError.range(optimizationLevel, 0, 6, 'png.optimizationLevel');
    }
  }
}

/// GIF-specific settings.
final class GifOptions {
  /// Creates GIF settings matching libcaesium defaults.
  const GifOptions({this.quality = 80});

  /// Lossy quality from 1 to 100.
  final int quality;

  void validate() {
    if (quality < 1 || quality > 100) {
      throw RangeError.range(quality, 1, 100, 'gif.quality');
    }
  }
}

/// WebP-specific settings.
final class WebpOptions {
  /// Creates WebP settings matching libcaesium defaults.
  const WebpOptions({this.quality = 80, this.lossless = false});

  /// Lossy quality from 0 to 100.
  final int quality;

  /// Whether to encode losslessly.
  final bool lossless;

  void validate() => _validateQuality('webp.quality', quality);
}

/// TIFF-specific settings.
final class TiffOptions {
  /// Creates TIFF settings matching libcaesium defaults.
  const TiffOptions({
    this.compression = TiffCompression.deflate,
    this.deflateLevel = TiffDeflateLevel.balanced,
  });

  /// Compression algorithm.
  final TiffCompression compression;

  /// Deflate level, used when [compression] is [TiffCompression.deflate].
  final TiffDeflateLevel deflateLevel;
}

/// Optional output dimensions.
final class ResizeOptions {
  /// Creates resize settings.
  ///
  /// When only one dimension is provided, the aspect ratio is preserved.
  /// Providing both dimensions resizes to that exact size.
  const ResizeOptions({this.width, this.height});

  /// Output width, or `null` to derive/retain it.
  final int? width;

  /// Output height, or `null` to derive/retain it.
  final int? height;

  void validate() {
    if (width == null && height == null) {
      throw ArgumentError(
        'ResizeOptions requires at least one output dimension.',
      );
    }
    if (width != null && (width! <= 0 || width! > 0xffffffff)) {
      throw RangeError.range(width!, 1, 0xffffffff, 'resize.width');
    }
    if (height != null && (height! <= 0 || height! > 0xffffffff)) {
      throw RangeError.range(height!, 1, 0xffffffff, 'resize.height');
    }
  }
}

/// Complete compression and conversion configuration.
final class CaesiumOptions {
  /// Creates settings matching libcaesium defaults.
  const CaesiumOptions({
    this.keepMetadata = false,
    this.jpeg = const JpegOptions(),
    this.png = const PngOptions(),
    this.gif = const GifOptions(),
    this.webp = const WebpOptions(),
    this.tiff = const TiffOptions(),
    this.resize,
  });

  /// Whether EXIF and other supported metadata should be retained.
  final bool keepMetadata;

  /// JPEG settings.
  final JpegOptions jpeg;

  /// PNG settings.
  final PngOptions png;

  /// GIF settings.
  final GifOptions gif;

  /// WebP settings.
  final WebpOptions webp;

  /// TIFF settings.
  final TiffOptions tiff;

  /// Optional output dimensions.
  final ResizeOptions? resize;

  /// Validates the complete configuration.
  void validate() {
    jpeg.validate();
    png.validate();
    gif.validate();
    webp.validate();
    resize?.validate();
  }
}

/// Result of an in-memory operation.
final class CaesiumMemoryResult {
  /// Creates an immutable operation result.
  CaesiumMemoryResult({
    required this.bytes,
    required this.inputSize,
    required this.outputSize,
  });

  /// Encoded output bytes.
  final Uint8List bytes;

  /// Encoded input size in bytes.
  final int inputSize;

  /// Encoded output size in bytes.
  final int outputSize;

  /// Positive when the operation saved space.
  int get savedBytes => inputSize - outputSize;

  /// Fraction of the original size saved. Negative means output grew.
  double get savingRatio => inputSize == 0 ? 0 : savedBytes / inputSize;
}

/// Result of a file operation.
final class CaesiumFileResult {
  /// Creates an immutable file result.
  const CaesiumFileResult({
    required this.inputPath,
    required this.outputPath,
    required this.inputSize,
    required this.outputSize,
  });

  /// Canonical or provided input path.
  final String inputPath;

  /// Output path.
  final String outputPath;

  /// Encoded input size in bytes.
  final int inputSize;

  /// Encoded output size in bytes.
  final int outputSize;

  /// Positive when the operation saved space.
  int get savedBytes => inputSize - outputSize;

  /// Fraction of the original size saved. Negative means output grew.
  double get savingRatio => inputSize == 0 ? 0 : savedBytes / inputSize;
}

/// A native libcaesium failure.
final class CaesiumException implements Exception {
  /// Creates a native failure.
  const CaesiumException(this.code, this.message);

  /// Stable native or libcaesium error code.
  final int code;

  /// Human-readable failure description.
  final String message;

  @override
  String toString() => 'CaesiumException($code): $message';
}

void _validateQuality(String name, int value) {
  if (value < 0 || value > 100) {
    throw RangeError.range(value, 0, 100, name);
  }
}
