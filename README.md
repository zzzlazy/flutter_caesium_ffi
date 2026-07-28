# flutter_caesium_ffi

English | [简体中文](README_zh-CN.md)

[![pub package](https://img.shields.io/pub/v/flutter_caesium_ffi.svg)](https://pub.dev/packages/flutter_caesium_ffi)
[![pub points](https://img.shields.io/pub/points/flutter_caesium_ffi)](https://pub.dev/packages/flutter_caesium_ffi/score)
[![CI](https://github.com/zzzlazy/flutter_caesium_ffi/actions/workflows/ci.yml/badge.svg)](https://github.com/zzzlazy/flutter_caesium_ffi/actions/workflows/ci.yml)
[![license: AGPL-3.0-or-later](https://img.shields.io/badge/license-AGPL--3.0--or--later-blue.svg)](LICENSE)

Fast, high-quality, cross-platform image compression for Flutter. Compress,
resize, convert, or target a file size for JPEG, PNG, WebP, GIF, and TIFF using
one Dart API across Android, iOS, macOS, Windows, Linux, and web.

Native platforms use
[`libcaesium` 0.20.3](https://github.com/Lymphatus/libcaesium) through a stable
C ABI, Dart FFI, and Flutter Native Assets. Browsers use
[`libcaesium-wasm` 0.5.0](https://github.com/zzzlazy/libcaesium-wasm).

The package supports JPEG, PNG, WebP, GIF, and TIFF on Android, iOS, macOS,
Windows, and Linux. Web supports in-memory JPEG, PNG, and WebP compression and
conversion.
Native libraries and web assets are bundled, so consuming applications do not
need Rust, Cargo, npm, manual script tags, or a package-specific native source
build.

## Features

- High-quality image compression powered by the Caesium/libcaesium codecs
- JPEG, PNG, WebP, GIF, and TIFF compression on native platforms
- Image resize and format conversion with metadata controls
- Best-effort target file size compression
- Memory and file path APIs running outside the Flutter UI isolate
- Bundled native binaries and WebAssembly: no consumer-side Rust/Cargo setup
- One package for Flutter mobile, desktop, and web

> **License notice:** this package and its bundled native code are licensed
> under AGPL-3.0-or-later. Applications that distribute or provide network
> access to a modified or combined work must satisfy the AGPL and all applicable
> third-party license obligations. Review [LICENSE](LICENSE) and
> [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) before shipping.

## Requirements

- Flutter 3.38.10 or newer
- Dart 3.10 or newer
- A browser with WebAssembly and JavaScript module support
- Android 5.0 / API 21 or newer
- iOS 12.0 or newer
- macOS 10.14 or newer
- Linux x86_64 with glibc 2.31 or newer
- Windows x64

## Installation

Install the published package:

```sh
flutter pub add flutter_caesium_ffi
```

Or add it manually:

```yaml
dependencies:
  flutter_caesium_ffi: ^2.0.2
```

To track unreleased changes from the default branch instead:

```yaml
dependencies:
  flutter_caesium_ffi:
    git:
      url: https://github.com/zzzlazy/flutter_caesium_ffi.git
      ref: main
```

Then run `flutter pub get` and build the application normally. The Native
Assets hook selects and bundles the matching precompiled library without
network access. Rust is only needed when modifying or rebuilding the native
wrapper. Applications still need Flutter's normal target-platform build
environment, such as Xcode or the Android SDK/NDK.

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
| macOS | arm64, x86_64 |
| Windows | x64 MSVC |
| Linux | x86_64, glibc 2.31+ |
| Web | WebAssembly, JPEG/PNG/WebP |

## Building native libraries

End users do not need these steps. Contributors need Rust 1.92.0 plus the
platform SDK. These commands regenerate the precompiled dynamic libraries that
the Native Assets hook selects; the hook never invokes Cargo:

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

The native workflow builds each platform binary, verifies example application
linking from the checked-in binaries before rebuilding them, combines a
complete package artifact, and runs `dart pub publish --dry-run`. It does not
publish to pub.dev. Checksums for the checked-in binaries are in
[`NATIVE_CHECKSUMS.sha256`](NATIVE_CHECKSUMS.sha256).

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release
cargo +1.92.0 test --manifest-path rust/Cargo.toml
```

To run the Native Assets integration tests:

```sh
flutter test test/native_integration_test.dart
```

See the runnable app in [`example`](example).
