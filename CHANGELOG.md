## Unreleased

## 2.0.2

- Explicitly declared Android, iOS, Linux, macOS, web, and Windows support so
  pub.dev displays all six supported Flutter platforms.

## 2.0.1

- Updated `code_assets` and the `hooks` compatibility range to their latest
  stable release series.

## 2.0.0

- **Breaking:** Raised the minimum versions to Flutter 3.38.10 and Dart 3.10.
- Replaced platform-specific FFI plugin packaging with a Native Assets build
  hook and `@Native` bindings.
- Kept all native libraries precompiled and bundled so consuming applications
  do not need Rust, Cargo, package-specific source builds, or package-initiated
  build-time downloads.
- Replaced Apple static XCFrameworks with target-specific dynamic libraries.
- Preserved the existing public Dart API, native C ABI, supported
  architectures, and WebAssembly implementation.
- Added a Simplified Chinese README.
- Improved package description, topics, installation guidance, and
  discoverability metadata.

## 1.0.1

- Fixed Web interop analysis on current Dart SDKs.
- Hid platform-specific implementation libraries from the public API surface so
  pub.dev can detect all supported Flutter platforms.

## 1.0.0

- Added Flutter web support through bundled `libcaesium-wasm` assets.
- Added lazy browser initialization and in-memory compression, target-size, and
  conversion APIs for JPEG, PNG, and WebP.
- Added a web example target and release-build coverage.

## 0.1.0

- Added memory and file compression, conversion, and target-size APIs.
- Added JPEG, PNG, WebP, GIF, TIFF, resize, and metadata options.
- Added a panic-safe Rust C ABI backed by `libcaesium` 0.20.3.
- Added prebuilt native packaging for Android, iOS, macOS, Linux, and Windows.
- Added background-isolate execution, generated FFI bindings, tests, example,
  rebuild scripts, and multi-platform CI.
