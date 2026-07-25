@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports the bundled WebAssembly version', () {
    expect(FlutterCaesiumFfi.nativeVersion, contains('wasm'));
  });

  test(
    'rejects browser-only unsupported operations before loading WASM',
    () async {
      final Uint8List encodedInput = Uint8List.fromList(<int>[1, 2, 3, 4]);

      await expectLater(
        FlutterCaesiumFfi.convert(encodedInput, format: CaesiumFormat.gif),
        throwsUnsupportedError,
      );
      await expectLater(
        FlutterCaesiumFfi.compressFile('input.png', 'output.png'),
        throwsUnsupportedError,
      );
    },
  );

  test('validates web-specific integer limits before loading WASM', () async {
    await expectLater(
      FlutterCaesiumFfi.compress(
        Uint8List.fromList(<int>[1, 2, 3, 4]),
        options: const CaesiumOptions(resize: ResizeOptions(width: 1000000)),
      ),
      throwsRangeError,
    );
  });
}
