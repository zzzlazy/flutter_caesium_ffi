# flutter_caesium_ffi

Fast image compression for Flutter, backed by
[`libcaesium` 0.20.3](https://github.com/Lymphatus/libcaesium) through a stable
C ABI and Dart FFI on native platforms, and
[`libcaesium-wasm` 0.5.0](https://github.com/zzzlazy/libcaesium-wasm) in
browsers.

The package supports JPEG, PNG, WebP, GIF, and TIFF on Android, iOS, macOS,
Windows, and Linux. Web supports in-memory JPEG, PNG, and WebP compression and
conversion.
Native libraries and web assets are bundled, so consuming applications do not
need Rust, Cargo, npm, a C compiler, or manual script tags.

> **License notice:** this package and its bundled native code are licensed
> under AGPL-3.0-or-later. Applications that distribute or provide network
> access to a modified or combined work must satisfy the AGPL and all applicable
> third-party license obligations. Review [LICENSE](LICENSE) and
> [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) before shipping.

## Requirements

- Flutter 3.22 or newer
- Dart 3.4 or newer
- A browser with WebAssembly and JavaScript module support
- Android 5.0 / API 21 or newer
- iOS 12.0 or newer
- macOS 10.14 or newer
- Linux x86_64 with glibc 2.31 or newer
- Windows x64

## Installation

Until the first pub.dev release, depend directly on the repository:

```yaml
dependencies:
  flutter_caesium_ffi:
    git:
      url: https://github.com/zzzlazy/flutter_caesium_ffi.git
      ref: main
```

Then run `flutter pub get` and build the application normally. Native binaries
and the WebAssembly module are already bundled. Rust is only needed when
modifying or rebuilding the wrappers.

## Usage

The memory API works on native platforms and web:

```dart
import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';

final result = await FlutterCaesiumFfi.compress(
  encodedImageBytes,
  options: const CaesiumOptions(
    keepMetadata: false,
    jpeg: JpegOptions(quality: 75, progressive: true),
    resize: ResizeOptions(width: 1600),
  ),
);

print('${result.inputSize} -> ${result.outputSize} bytes');
print('native: ${FlutterCaesiumFfi.nativeVersion}');
```

The public operations are `compress`, `compressFile`, `compressToSize`,
`compressFileToSize`, `convert`, `convertFile`, and `nativeVersion`.

Native image work runs on a background isolate. On web, the WASM module is
loaded lazily on the first call and currently runs on the browser main thread.

## Platform API support

| Operation | Native | Web |
| --- | --- | --- |
| `compress` | JPEG, PNG, WebP, GIF, TIFF | JPEG, PNG, WebP |
| `compressToSize` | Yes | Yes |
| `convert` | Yes | JPEG, PNG, WebP output |
| File path APIs | Yes | Not available in browsers |

On web, `jpeg.preserveIcc` is not available in the older libcaesium version used
by the WASM build. Web resize dimensions are limited to 999999.

## Options and behavior

`CaesiumOptions` exposes JPEG, PNG, WebP, GIF, TIFF, resize, and metadata
settings. Defaults match `libcaesium`: quality 80, metadata removed, progressive
JPEG enabled, and PNG optimization level 3.

File operations never overwrite an existing output. Empty input, invalid
quality or dimensions, missing input files, missing output directories, and
equal input/output paths fail before encoding starts. Native failures are
reported as `CaesiumException(code, message)`.

Target-size compression is best effort because some inputs or formats cannot
reach every requested size. Set `returnSmallest: true` to return the smallest
candidate when the exact target cannot be reached.

## Bundled platforms

| Platform | Bundled architecture |
| --- | --- |
| Android | `arm64-v8a`, `armeabi-v7a`, `x86_64` |
| iOS | arm64 device; arm64/x86_64 simulator |
| macOS | arm64/x86_64 universal |
| Windows | x64 MSVC |
| Linux | x86_64, glibc 2.31+ |
| Web | WebAssembly, JPEG/PNG/WebP |

## Building native libraries

End users do not need these steps. Contributors need Rust 1.92.0 plus the
platform SDK:

```sh
dart run tool/build_native.dart --platform macos
dart run tool/build_native.dart --platform ios
dart run tool/build_native.dart --platform android
dart run tool/build_native.dart --platform linux
dart run tool/build_native.dart --platform windows
```

Android builds also require `cargo-ndk`. Regenerate private Dart bindings after
changing the C header:

```sh
dart run ffigen --config ffigen.yaml
```

Release Linux binaries use Zig to pin the glibc baseline:

```sh
FLUTTER_CAESIUM_LINUX_GLIBC=2.31 \
  dart run tool/build_native.dart --platform linux
```

The regular GitHub Actions workflow runs Dart formatting, analysis, tests, and
bundled-binary checksum verification for every push and pull request. The
separate native workflow only runs when Rust, C ABI, bindings, native packaging,
or prebuilt-binary files change. Version tags and manual dispatches always run
the complete native workflow.

The native workflow builds and strips each platform binary, verifies example
application linking from the checked-in binaries before rebuilding them,
combines a complete package artifact, and runs `dart pub publish --dry-run`.
It does not publish to pub.dev. Checksums for the checked-in binaries are in
[`NATIVE_CHECKSUMS.sha256`](NATIVE_CHECKSUMS.sha256).

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release
cargo +1.92.0 test --manifest-path rust/Cargo.toml
```

To run native integration tests against a local library:

```sh
FLUTTER_CAESIUM_FFI_LIBRARY=/absolute/path/to/libflutter_caesium_ffi.dylib \
  flutter test test/native_integration_test.dart
```

See the runnable app in [`example`](example).
