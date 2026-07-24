# flutter_caesium_ffi example

Run this app to compress, target-size, and convert an embedded PNG, then inspect
the input/output statistics:

```sh
flutter run
flutter run -d chrome
```

The parent package contains the native libraries and WebAssembly assets.
Contributors can rebuild native code with
`dart run tool/build_native.dart --platform host`.
