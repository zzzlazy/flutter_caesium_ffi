## Unreleased

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
