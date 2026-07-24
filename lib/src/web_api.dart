import 'dart:js_interop';
import 'dart:typed_data';

import 'models.dart';

const String _webVersion = '0.5.0+libcaesium-0.18.0-wasm';
const String _moduleAsset =
    'assets/packages/flutter_caesium_ffi/web/libcaesium_wasm/index.js';
const String _wasmAsset =
    'assets/packages/flutter_caesium_ffi/web/libcaesium_wasm/'
    'libcaesium_wasm.wasm';

/// Internal operation selector shared with the public API.
enum NativeOperation { compress, compressToSize, convert }

String nativeVersionSync() => _webVersion;

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
  _validateWebOptions(options);
  if (_isGifOrTiff(input)) {
    throw UnsupportedError(
      'The bundled libcaesium-wasm build supports JPEG, PNG, and WebP only.',
    );
  }
  if (operation == NativeOperation.convert &&
      format != CaesiumFormat.jpeg &&
      format != CaesiumFormat.png &&
      format != CaesiumFormat.webp) {
    throw UnsupportedError(
      'Web conversion supports JPEG, PNG, and WebP output only.',
    );
  }
  if (maxOutputBytes != null && maxOutputBytes > 0x7fffffff) {
    throw RangeError.range(
      maxOutputBytes,
      1,
      0x7fffffff,
      'maxOutputBytes',
      'libcaesium-wasm accepts a signed 32-bit target size.',
    );
  }

  // Keep ownership independent from caller mutations while WASM initializes.
  final Uint8List inputCopy = Uint8List.fromList(input);
  final _CaesiumModule module = await _module;
  final _CompressionOptions webOptions = _toWebOptions(options);
  final _CompressionResult result = switch (operation) {
    NativeOperation.compress => module.compress(inputCopy.toJS, webOptions),
    NativeOperation.compressToSize => module.compressToSize(
        inputCopy.toJS,
        maxOutputBytes!,
        webOptions,
        returnSmallest,
      ),
    NativeOperation.convert =>
      module.convert(inputCopy.toJS, format!.nativeValue, webOptions),
  };

  if (!result.status) {
    final int code = result.errorCode == 0 ? 20998 : result.errorCode;
    throw CaesiumException(code, 'libcaesium-wasm operation failed.');
  }
  final Uint8List output = Uint8List.fromList(result.compressedImage.toDart);
  return CaesiumMemoryResult(
    bytes: output,
    inputSize: inputCopy.length,
    outputSize: output.length,
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
  _validateOperation(operation, format, maxOutputBytes);
  throw UnsupportedError(
    'File path operations are unavailable in browsers. Read the input as '
    'bytes and use a FlutterCaesiumFfi memory API instead.',
  );
}

void _validateWebOptions(CaesiumOptions options) {
  final ResizeOptions? resize = options.resize;
  if (resize?.width case final int width when width > 999999) {
    throw RangeError.range(width, 1, 999999, 'resize.width');
  }
  if (resize?.height case final int height when height > 999999) {
    throw RangeError.range(height, 1, 999999, 'resize.height');
  }
}

bool _isGifOrTiff(Uint8List input) {
  final bool gif = input.length >= 4 &&
      input[0] == 0x47 &&
      input[1] == 0x49 &&
      input[2] == 0x46 &&
      input[3] == 0x38;
  final bool littleEndianTiff = input.length >= 4 &&
      input[0] == 0x49 &&
      input[1] == 0x49 &&
      input[2] == 0x2a &&
      input[3] == 0x00;
  final bool bigEndianTiff = input.length >= 4 &&
      input[0] == 0x4d &&
      input[1] == 0x4d &&
      input[2] == 0x00 &&
      input[3] == 0x2a;
  return gif || littleEndianTiff || bigEndianTiff;
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

Future<_CaesiumModule> get _module => _moduleFuture ??= _loadModule();
Future<_CaesiumModule>? _moduleFuture;

Future<_CaesiumModule> _loadModule() async {
  final Uri baseUri = Uri.parse(_documentBaseUri);
  final String moduleUrl = baseUri.resolve(_moduleAsset).toString();
  final String wasmUrl = baseUri.resolve(_wasmAsset).toString();
  final JSObject namespace = await importModule(moduleUrl).toDart;
  final _CaesiumModule module = _CaesiumModule._(namespace);
  await module.initialize(wasmUrl).toDart;
  return module;
}

_CompressionOptions _toWebOptions(CaesiumOptions options) {
  return _CompressionOptions(
    jpeg: _JpegOptions(
      quality: options.jpeg.quality,
      chromaSubsampling: options.jpeg.chromaSubsampling.nativeValue,
      progressive: options.jpeg.progressive,
      optimize: options.jpeg.optimize,
    ),
    png: _PngOptions(
      quality: options.png.quality,
      optimizationLevel: options.png.optimizationLevel,
      forceZopfli: options.png.forceZopfli,
      optimize: options.png.optimize,
    ),
    webp: _WebpOptions(
      quality: options.webp.quality,
      lossless: options.webp.lossless,
    ),
    tiff: _TiffOptions(
      // The upstream JS wrapper maps 4 to libcaesium's Uncompressed variant.
      compression: options.tiff.compression == TiffCompression.uncompressed
          ? 4
          : options.tiff.compression.nativeValue,
      deflateLevel: options.tiff.deflateLevel.nativeValue,
    ),
    gif: _GifOptions(quality: options.gif.quality),
    keepMetadata: options.keepMetadata,
    width: options.resize?.width ?? 0,
    height: options.resize?.height ?? 0,
  );
}

@JS('document.baseURI')
external String get _documentBaseUri;

extension type _CaesiumModule._(JSObject _) implements JSObject {
  external JSPromise<JSObject> initialize(String wasmUrl);

  external _CompressionResult compress(
    JSUint8Array input,
    _CompressionOptions options,
  );

  external _CompressionResult compressToSize(
    JSUint8Array input,
    int maxSize,
    _CompressionOptions options,
    bool returnSmallest,
  );

  external _CompressionResult convert(
    JSUint8Array input,
    int outputFormat,
    _CompressionOptions options,
  );
}

extension type _CompressionResult._(JSObject _) implements JSObject {
  external bool get status;
  external int get errorCode;
  external JSUint8Array get compressedImage;
}

@JS()
@anonymous
extension type _CompressionOptions._(JSObject _) implements JSObject {
  external factory _CompressionOptions({
    required _JpegOptions jpeg,
    required _PngOptions png,
    required _WebpOptions webp,
    required _TiffOptions tiff,
    required _GifOptions gif,
    required bool keepMetadata,
    required int width,
    required int height,
  });
}

@JS()
@anonymous
extension type _JpegOptions._(JSObject _) implements JSObject {
  external factory _JpegOptions({
    required int quality,
    required int chromaSubsampling,
    required bool progressive,
    required bool optimize,
  });
}

@JS()
@anonymous
extension type _PngOptions._(JSObject _) implements JSObject {
  external factory _PngOptions({
    required int quality,
    required int optimizationLevel,
    required bool forceZopfli,
    required bool optimize,
  });
}

@JS()
@anonymous
extension type _WebpOptions._(JSObject _) implements JSObject {
  external factory _WebpOptions({
    required int quality,
    required bool lossless,
  });
}

@JS()
@anonymous
extension type _TiffOptions._(JSObject _) implements JSObject {
  external factory _TiffOptions({
    required int compression,
    required int deflateLevel,
  });
}

@JS()
@anonymous
extension type _GifOptions._(JSObject _) implements JSObject {
  external factory _GifOptions({required int quality});
}
