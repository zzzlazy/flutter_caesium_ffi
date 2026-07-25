import 'dart:typed_data';

import 'src/models.dart';
import 'src/platform_api.dart';

export 'src/models.dart';

/// High-performance image compression backed by libcaesium.
abstract final class FlutterCaesiumFfi {
  /// The bundled native or WebAssembly wrapper and libcaesium version.
  static String get nativeVersion => nativeVersionSync();

  /// Compresses an encoded image without changing its format.
  ///
  /// Web supports JPEG, PNG, and WebP through the bundled libcaesium WASM
  /// module.
  static Future<CaesiumMemoryResult> compress(
    Uint8List input, {
    CaesiumOptions options = const CaesiumOptions(),
  }) {
    return runMemoryOperation(
      NativeOperation.compress,
      input,
      options: options,
    );
  }

  /// Compresses an encoded image to at most [maxOutputBytes] where possible.
  static Future<CaesiumMemoryResult> compressToSize(
    Uint8List input, {
    required int maxOutputBytes,
    bool returnSmallest = false,
    CaesiumOptions options = const CaesiumOptions(),
  }) {
    return runMemoryOperation(
      NativeOperation.compressToSize,
      input,
      options: options,
      maxOutputBytes: maxOutputBytes,
      returnSmallest: returnSmallest,
    );
  }

  /// Converts an encoded image to [format].
  ///
  /// Web supports JPEG, PNG, and WebP output.
  static Future<CaesiumMemoryResult> convert(
    Uint8List input, {
    required CaesiumFormat format,
    CaesiumOptions options = const CaesiumOptions(),
  }) {
    return runMemoryOperation(
      NativeOperation.convert,
      input,
      options: options,
      format: format,
    );
  }

  /// Compresses [inputPath] into a new file at [outputPath].
  ///
  /// Existing output files are never overwritten.
  /// File operations are unavailable on web; use [compress] with bytes there.
  static Future<CaesiumFileResult> compressFile(
    String inputPath,
    String outputPath, {
    CaesiumOptions options = const CaesiumOptions(),
  }) {
    return runFileOperation(
      NativeOperation.compress,
      inputPath,
      outputPath,
      options: options,
    );
  }

  /// Compresses [inputPath] to at most [maxOutputBytes] where possible.
  ///
  /// Existing output files are never overwritten.
  /// File operations are unavailable on web; use [compressToSize] with bytes
  /// there.
  static Future<CaesiumFileResult> compressFileToSize(
    String inputPath,
    String outputPath, {
    required int maxOutputBytes,
    bool returnSmallest = false,
    CaesiumOptions options = const CaesiumOptions(),
  }) {
    return runFileOperation(
      NativeOperation.compressToSize,
      inputPath,
      outputPath,
      options: options,
      maxOutputBytes: maxOutputBytes,
      returnSmallest: returnSmallest,
    );
  }

  /// Converts [inputPath] into [format] at [outputPath].
  ///
  /// Existing output files are never overwritten.
  /// File operations are unavailable on web.
  static Future<CaesiumFileResult> convertFile(
    String inputPath,
    String outputPath, {
    required CaesiumFormat format,
    CaesiumOptions options = const CaesiumOptions(),
  }) {
    return runFileOperation(
      NativeOperation.convert,
      inputPath,
      outputPath,
      options: options,
      format: format,
    );
  }
}
