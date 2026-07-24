import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'flutter_caesium_ffi_bindings_generated.dart';
import 'models.dart';

const int _expectedAbiVersion = 1;

/// Internal operation selector shared with worker isolates.
enum NativeOperation { compress, compressToSize, convert }

String nativeVersionSync() => _NativeApi.instance.nativeVersion;

Future<CaesiumMemoryResult> runMemoryOperation(
  NativeOperation operation,
  Uint8List input, {
  required CaesiumOptions options,
  CaesiumFormat? format,
  int? maxOutputBytes,
  bool returnSmallest = false,
}) async {
  options.validate();
  if (input.isEmpty) {
    throw ArgumentError.value(input, 'input', 'Must not be empty.');
  }
  _validateOperation(operation, format, maxOutputBytes);
  final TransferableTypedData transferable =
      TransferableTypedData.fromList(<Uint8List>[input]);
  final _MemoryPayload payload = await Isolate.run<_MemoryPayload>(() {
    final Uint8List materialized = transferable.materialize().asUint8List();
    final Uint8List output = _NativeApi.instance.runMemory(
      operation,
      materialized,
      options,
      format: format,
      maxOutputBytes: maxOutputBytes,
      returnSmallest: returnSmallest,
    );
    return _MemoryPayload(
      TransferableTypedData.fromList(<Uint8List>[output]),
      materialized.length,
      output.length,
    );
  });
  return CaesiumMemoryResult(
    bytes: payload.bytes.materialize().asUint8List(),
    inputSize: payload.inputSize,
    outputSize: payload.outputSize,
  );
}

Future<CaesiumFileResult> runFileOperation(
  NativeOperation operation,
  String inputPath,
  String outputPath, {
  required CaesiumOptions options,
  CaesiumFormat? format,
  int? maxOutputBytes,
  bool returnSmallest = false,
}) async {
  options.validate();
  _validateFileArguments(inputPath, outputPath);
  _validateOperation(operation, format, maxOutputBytes);
  return Isolate.run<CaesiumFileResult>(() {
    final File input = File(inputPath);
    final int inputSize = input.lengthSync();
    _NativeApi.instance.runFile(
      operation,
      inputPath,
      outputPath,
      options,
      format: format,
      maxOutputBytes: maxOutputBytes,
      returnSmallest: returnSmallest,
    );
    final int outputSize = File(outputPath).lengthSync();
    return CaesiumFileResult(
      inputPath: inputPath,
      outputPath: outputPath,
      inputSize: inputSize,
      outputSize: outputSize,
    );
  });
}

void _validateOperation(
  NativeOperation operation,
  CaesiumFormat? format,
  int? maxOutputBytes,
) {
  if (operation == NativeOperation.convert && format == null) {
    throw ArgumentError.notNull('format');
  }
  if (operation == NativeOperation.compressToSize &&
      (maxOutputBytes == null || maxOutputBytes <= 0)) {
    throw RangeError.value(
      maxOutputBytes ?? 0,
      'maxOutputBytes',
      'Must be positive.',
    );
  }
}

void _validateFileArguments(String inputPath, String outputPath) {
  if (inputPath.isEmpty || outputPath.isEmpty) {
    throw ArgumentError('Input and output paths must not be empty.');
  }
  final File input = File(inputPath);
  final File output = File(outputPath);
  if (!input.existsSync()) {
    throw ArgumentError.value(inputPath, 'inputPath', 'File does not exist.');
  }
  if (output.existsSync() || Directory(outputPath).existsSync()) {
    throw ArgumentError.value(
      outputPath,
      'outputPath',
      'Existing paths are never overwritten.',
    );
  }
  final Directory parent = output.parent;
  if (!parent.existsSync()) {
    throw ArgumentError.value(
      outputPath,
      'outputPath',
      'Parent directory does not exist.',
    );
  }
  final String inputCanonical = input.resolveSymbolicLinksSync();
  final String outputCanonical = <String>[
    parent.resolveSymbolicLinksSync(),
    output.absolute.path.split(Platform.pathSeparator).last,
  ].join(Platform.pathSeparator);
  if (inputCanonical == outputCanonical) {
    throw ArgumentError('Input and output paths must be different.');
  }
}

final class _MemoryPayload {
  const _MemoryPayload(this.bytes, this.inputSize, this.outputSize);

  final TransferableTypedData bytes;
  final int inputSize;
  final int outputSize;
}

final class _NativeApi {
  _NativeApi._() : bindings = FlutterCaesiumFfiBindings(_openLibrary()) {
    final int actual = bindings.fc_abi_version();
    if (actual != _expectedAbiVersion) {
      throw StateError(
        'flutter_caesium_ffi ABI mismatch: expected '
        '$_expectedAbiVersion, found $actual.',
      );
    }
  }

  static final _NativeApi instance = _NativeApi._();

  final FlutterCaesiumFfiBindings bindings;

  String get nativeVersion =>
      bindings.fc_native_version().cast<Utf8>().toDartString();

  Uint8List runMemory(
    NativeOperation operation,
    Uint8List input,
    CaesiumOptions options, {
    CaesiumFormat? format,
    int? maxOutputBytes,
    bool returnSmallest = false,
  }) {
    final Pointer<Uint8> inputPointer = calloc<Uint8>(input.length);
    final Pointer<FcOptions> optionsPointer = calloc<FcOptions>();
    final Pointer<FcBuffer> outputPointer = calloc<FcBuffer>();
    final Pointer<Pointer<Char>> errorPointer = calloc<Pointer<Char>>();
    inputPointer.asTypedList(input.length).setAll(0, input);
    _writeOptions(optionsPointer.ref, options);

    try {
      final int code = switch (operation) {
        NativeOperation.compress => bindings.fc_compress_memory(
            inputPointer,
            input.length,
            optionsPointer,
            outputPointer,
            errorPointer,
          ),
        NativeOperation.compressToSize => bindings.fc_compress_to_size_memory(
            inputPointer,
            input.length,
            maxOutputBytes!,
            returnSmallest ? 1 : 0,
            optionsPointer,
            outputPointer,
            errorPointer,
          ),
        NativeOperation.convert => bindings.fc_convert_memory(
            inputPointer,
            input.length,
            format!.nativeValue,
            optionsPointer,
            outputPointer,
            errorPointer,
          ),
      };
      _throwIfFailed(code, errorPointer);
      final FcBuffer output = outputPointer.ref;
      if (output.length > 0 && output.data == nullptr) {
        throw const CaesiumException(
          20998,
          'Native operation returned an invalid output buffer.',
        );
      }
      return Uint8List.fromList(output.data.asTypedList(output.length));
    } finally {
      _freeError(errorPointer);
      bindings.fc_buffer_free(outputPointer);
      calloc
        ..free(inputPointer)
        ..free(optionsPointer)
        ..free(outputPointer)
        ..free(errorPointer);
    }
  }

  void runFile(
    NativeOperation operation,
    String inputPath,
    String outputPath,
    CaesiumOptions options, {
    CaesiumFormat? format,
    int? maxOutputBytes,
    bool returnSmallest = false,
  }) {
    final Pointer<Utf8> inputPointer = inputPath.toNativeUtf8();
    final Pointer<Utf8> outputPointer = outputPath.toNativeUtf8();
    final Pointer<FcOptions> optionsPointer = calloc<FcOptions>();
    final Pointer<Pointer<Char>> errorPointer = calloc<Pointer<Char>>();
    _writeOptions(optionsPointer.ref, options);

    try {
      final int code = switch (operation) {
        NativeOperation.compress => bindings.fc_compress_file(
            inputPointer.cast(),
            outputPointer.cast(),
            optionsPointer,
            errorPointer,
          ),
        NativeOperation.compressToSize => bindings.fc_compress_to_size_file(
            inputPointer.cast(),
            outputPointer.cast(),
            maxOutputBytes!,
            returnSmallest ? 1 : 0,
            optionsPointer,
            errorPointer,
          ),
        NativeOperation.convert => bindings.fc_convert_file(
            inputPointer.cast(),
            outputPointer.cast(),
            format!.nativeValue,
            optionsPointer,
            errorPointer,
          ),
      };
      _throwIfFailed(code, errorPointer);
    } finally {
      _freeError(errorPointer);
      calloc
        ..free(inputPointer)
        ..free(outputPointer)
        ..free(optionsPointer)
        ..free(errorPointer);
    }
  }

  void _throwIfFailed(
    int code,
    Pointer<Pointer<Char>> errorPointer,
  ) {
    if (code == 0) {
      return;
    }
    final Pointer<Char> nativeMessage = errorPointer.value;
    final String message = nativeMessage == nullptr
        ? 'Native image operation failed.'
        : nativeMessage.cast<Utf8>().toDartString();
    throw CaesiumException(code, message);
  }

  void _freeError(Pointer<Pointer<Char>> errorPointer) {
    final Pointer<Char> message = errorPointer.value;
    if (message != nullptr) {
      bindings.fc_string_free(message);
      errorPointer.value = nullptr;
    }
  }
}

void _writeOptions(FcOptions target, CaesiumOptions source) {
  target
    ..keep_metadata = source.keepMetadata ? 1 : 0
    ..jpeg_quality = source.jpeg.quality
    ..jpeg_chroma_subsampling = source.jpeg.chromaSubsampling.nativeValue
    ..jpeg_progressive = source.jpeg.progressive ? 1 : 0
    ..jpeg_optimize = source.jpeg.optimize ? 1 : 0
    ..jpeg_preserve_icc = source.jpeg.preserveIcc ? 1 : 0
    ..png_quality = source.png.quality
    ..png_optimization_level = source.png.optimizationLevel
    ..png_force_zopfli = source.png.forceZopfli ? 1 : 0
    ..png_optimize = source.png.optimize ? 1 : 0
    ..gif_quality = source.gif.quality
    ..webp_quality = source.webp.quality
    ..webp_lossless = source.webp.lossless ? 1 : 0
    ..tiff_compression = source.tiff.compression.nativeValue
    ..tiff_deflate_level = source.tiff.deflateLevel.nativeValue
    ..width = source.resize?.width ?? 0
    ..height = source.resize?.height ?? 0;
}

DynamicLibrary _openLibrary() {
  final String? override = Platform.environment['FLUTTER_CAESIUM_FFI_LIBRARY'];
  if (override != null && override.isNotEmpty) {
    return DynamicLibrary.open(override);
  }
  if (Platform.isIOS || Platform.isMacOS) {
    final DynamicLibrary process = DynamicLibrary.process();
    try {
      process.lookup<NativeFunction<Uint32 Function()>>('fc_abi_version');
      return process;
    } on ArgumentError {
      final List<String> candidates = <String>[
        'flutter_caesium_ffi.framework/flutter_caesium_ffi',
        'libflutter_caesium_ffi.dylib',
      ];
      for (final String candidate in candidates) {
        try {
          return DynamicLibrary.open(candidate);
        } on ArgumentError {
          continue;
        }
      }
      rethrow;
    }
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('libflutter_caesium_ffi.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('flutter_caesium_ffi.dll');
  }
  throw UnsupportedError(
    'flutter_caesium_ffi does not support ${Platform.operatingSystem}.',
  );
}
