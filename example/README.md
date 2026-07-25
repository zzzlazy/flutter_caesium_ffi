# flutter_caesium_ffi example

Run this app to compress, target-size, and convert an embedded PNG, then inspect
the input/output statistics:

```sh
flutter run
flutter run -d chrome
```

The parent package uses Native Assets to bundle the matching precompiled native
library and contains the WebAssembly assets. Contributors can rebuild native code with
`dart run tool/build_native.dart --platform host`.
