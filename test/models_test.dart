import 'dart:typed_data';

import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaesiumOptions', () {
    test('libcaesium defaults are valid', () {
      const CaesiumOptions().validate();
    });

    test('rejects invalid quality values', () {
      expect(
        () => const CaesiumOptions(
          jpeg: JpegOptions(quality: 101),
        ).validate(),
        throwsRangeError,
      );
      expect(
        () => const CaesiumOptions(
          gif: GifOptions(quality: 0),
        ).validate(),
        throwsRangeError,
      );
    });

    test('validates resize dimensions', () {
      expect(
        () => const CaesiumOptions(
          resize: ResizeOptions(),
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => const CaesiumOptions(
          resize: ResizeOptions(width: 0),
        ).validate(),
        throwsRangeError,
      );
      expect(
        () => const CaesiumOptions(
          resize: ResizeOptions(width: 0x100000000),
        ).validate(),
        throwsRangeError,
      );
      const CaesiumOptions(
        resize: ResizeOptions(width: 1920),
      ).validate();
    });
  });

  test('memory result exposes compression statistics', () {
    final CaesiumMemoryResult result = CaesiumMemoryResult(
      bytes: Uint8List(60),
      inputSize: 100,
      outputSize: 60,
    );
    expect(result.savedBytes, 40);
    expect(result.savingRatio, closeTo(0.4, 0.0001));
  });

  test('file result supports growth statistics', () {
    const CaesiumFileResult result = CaesiumFileResult(
      inputPath: 'input.png',
      outputPath: 'output.webp',
      inputSize: 80,
      outputSize: 100,
    );
    expect(result.savedBytes, -20);
    expect(result.savingRatio, closeTo(-0.25, 0.0001));
  });

  test('native enums have stable ABI values', () {
    expect(CaesiumFormat.values.map((CaesiumFormat value) => value.nativeValue),
        <int>[0, 1, 2, 3, 4]);
    expect(JpegChromaSubsampling.cs420.nativeValue, 420);
    expect(TiffCompression.deflate.nativeValue, 2);
    expect(TiffDeflateLevel.balanced.nativeValue, 6);
  });

  test('public memory APIs validate before native loading', () async {
    await expectLater(
      FlutterCaesiumFfi.compress(Uint8List(0)),
      throwsArgumentError,
    );
    await expectLater(
      FlutterCaesiumFfi.compressToSize(
        Uint8List.fromList(<int>[1]),
        maxOutputBytes: 0,
      ),
      throwsRangeError,
    );
  });

  test('public file APIs reject invalid paths before native loading', () async {
    await expectLater(
      FlutterCaesiumFfi.compressFile('', 'output.jpg'),
      throwsArgumentError,
    );
    await expectLater(
      FlutterCaesiumFfi.convertFile(
        'same.jpg',
        'same.jpg',
        format: CaesiumFormat.png,
      ),
      throwsArgumentError,
    );
  });

  test('CaesiumException preserves code and message', () {
    const CaesiumException exception = CaesiumException(10403, 'decode failed');
    expect(exception.code, 10403);
    expect(exception.message, 'decode failed');
    expect(exception.toString(), 'CaesiumException(10403): decode failed');
  });
}
