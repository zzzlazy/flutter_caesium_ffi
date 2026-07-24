import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

const String _samplePng =
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFElEQVR4nGP4'
    'z8DAAMIM////ZwAAHu8E/KPItPcAAAAASUVORK5CYII=';

void main() {
  final bool nativeLibraryAvailable =
      Platform.environment['FLUTTER_CAESIUM_FFI_LIBRARY']?.isNotEmpty ?? false;

  group(
    'native integration',
    () {
      late Uint8List png;

      setUp(() => png = base64Decode(_samplePng));

      test('reports matching versions', () {
        expect(FlutterCaesiumFfi.nativeVersion, contains('libcaesium-0.20.3'));
      });

      test('compresses PNG bytes on a worker isolate', () async {
        final CaesiumMemoryResult result = await FlutterCaesiumFfi.compress(
          png,
          options: const CaesiumOptions(
            png: PngOptions(optimize: true),
          ),
        );
        expect(result.bytes, isNotEmpty);
        expect(result.outputSize, result.bytes.length);
        expect(result.bytes.take(8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
      });

      test('converts PNG bytes to WebP', () async {
        final CaesiumMemoryResult result = await FlutterCaesiumFfi.convert(
          png,
          format: CaesiumFormat.webp,
        );
        expect(ascii.decode(result.bytes.sublist(0, 4)), 'RIFF');
        expect(ascii.decode(result.bytes.sublist(8, 12)), 'WEBP');
      });

      test('converts to and recompresses every supported output format',
          () async {
        final Map<CaesiumFormat, bool Function(Uint8List)> signatures =
            <CaesiumFormat, bool Function(Uint8List)>{
          CaesiumFormat.jpeg: (Uint8List bytes) =>
              bytes[0] == 0xff && bytes[1] == 0xd8,
          CaesiumFormat.gif: (Uint8List bytes) =>
              ascii.decode(bytes.sublist(0, 4)) == 'GIF8',
          CaesiumFormat.webp: (Uint8List bytes) =>
              ascii.decode(bytes.sublist(0, 4)) == 'RIFF' &&
              ascii.decode(bytes.sublist(8, 12)) == 'WEBP',
          CaesiumFormat.tiff: (Uint8List bytes) =>
              (bytes[0] == 0x49 && bytes[1] == 0x49) ||
              (bytes[0] == 0x4d && bytes[1] == 0x4d),
        };

        for (final MapEntry<CaesiumFormat, bool Function(Uint8List)> entry
            in signatures.entries) {
          final CaesiumMemoryResult converted = await FlutterCaesiumFfi.convert(
            png,
            format: entry.key,
          );
          expect(entry.value(converted.bytes), isTrue, reason: entry.key.name);
          final CaesiumMemoryResult compressed =
              await FlutterCaesiumFfi.compress(converted.bytes);
          expect(compressed.bytes, isNotEmpty, reason: entry.key.name);
        }
      });

      test('supports target-size compression', () async {
        final CaesiumMemoryResult result =
            await FlutterCaesiumFfi.compressToSize(
          png,
          maxOutputBytes: 128,
          returnSmallest: true,
        );
        expect(result.bytes, isNotEmpty);
      });

      test('supports resize and lossless WebP options', () async {
        final CaesiumMemoryResult resized = await FlutterCaesiumFfi.compress(
          png,
          options: const CaesiumOptions(
            resize: ResizeOptions(width: 2, height: 3),
          ),
        );
        expect(_readBigEndianUint32(resized.bytes, 16), 2);
        expect(_readBigEndianUint32(resized.bytes, 20), 3);

        final CaesiumMemoryResult lossless = await FlutterCaesiumFfi.convert(
          png,
          format: CaesiumFormat.webp,
          options: const CaesiumOptions(
            webp: WebpOptions(lossless: true),
          ),
        );
        expect(ascii.decode(lossless.bytes.sublist(0, 4)), 'RIFF');
      });

      test('removes or preserves EXIF metadata as configured', () async {
        final Uint8List jpeg = (await FlutterCaesiumFfi.convert(
          png,
          format: CaesiumFormat.jpeg,
        ))
            .bytes;
        final Uint8List jpegWithExif = _insertMinimalExif(jpeg);

        final CaesiumMemoryResult removed =
            await FlutterCaesiumFfi.compress(jpegWithExif);
        final CaesiumMemoryResult preserved = await FlutterCaesiumFfi.compress(
          jpegWithExif,
          options: const CaesiumOptions(keepMetadata: true),
        );

        expect(_containsAscii(removed.bytes, 'Exif'), isFalse);
        expect(_containsAscii(preserved.bytes, 'Exif'), isTrue);
      });

      test('repeated calls release native buffers safely', () async {
        for (int iteration = 0; iteration < 25; iteration++) {
          final CaesiumMemoryResult result =
              await FlutterCaesiumFfi.compress(png);
          expect(result.bytes, isNotEmpty);
        }
      });

      test('maps native failures to CaesiumException', () async {
        await expectLater(
          FlutterCaesiumFfi.compress(Uint8List.fromList(<int>[1, 2, 3, 4])),
          throwsA(
            isA<CaesiumException>()
                .having(
                    (CaesiumException error) => error.code, 'code', isNot(0))
                .having(
                  (CaesiumException error) => error.message,
                  'message',
                  isNotEmpty,
                ),
          ),
        );
      });

      test('writes files and protects existing output', () async {
        final Directory directory =
            await Directory.systemTemp.createTemp('flutter_caesium_ffi_test_');
        addTearDown(() => directory.delete(recursive: true));
        final File input = File('${directory.path}/input.png')
          ..writeAsBytesSync(png);
        final String output = '${directory.path}/output.webp';
        final CaesiumFileResult result = await FlutterCaesiumFfi.convertFile(
          input.path,
          output,
          format: CaesiumFormat.webp,
        );
        expect(result.inputSize, png.length);
        expect(result.outputSize, greaterThan(0));
        expect(File(output).existsSync(), isTrue);

        final String compressedPath = '${directory.path}/compressed.png';
        final CaesiumFileResult compressed =
            await FlutterCaesiumFfi.compressFile(
          input.path,
          compressedPath,
        );
        expect(compressed.outputSize, greaterThan(0));

        final String targetedPath = '${directory.path}/targeted.png';
        final CaesiumFileResult targeted =
            await FlutterCaesiumFfi.compressFileToSize(
          input.path,
          targetedPath,
          maxOutputBytes: 128,
          returnSmallest: true,
        );
        expect(targeted.outputSize, greaterThan(0));

        await expectLater(
          FlutterCaesiumFfi.convertFile(
            input.path,
            output,
            format: CaesiumFormat.webp,
          ),
          throwsArgumentError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set FLUTTER_CAESIUM_FFI_LIBRARY to a built native library.',
  );
}

int _readBigEndianUint32(Uint8List bytes, int offset) =>
    bytes.buffer.asByteData(bytes.offsetInBytes + offset, 4).getUint32(0);

Uint8List _insertMinimalExif(Uint8List jpeg) {
  const List<int> app1 = <int>[
    0xff,
    0xe1,
    0x00,
    0x16,
    0x45,
    0x78,
    0x69,
    0x66,
    0x00,
    0x00,
    0x4d,
    0x4d,
    0x00,
    0x2a,
    0x00,
    0x00,
    0x00,
    0x08,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
  ];
  return Uint8List.fromList(<int>[
    jpeg[0],
    jpeg[1],
    ...app1,
    ...jpeg.sublist(2),
  ]);
}

bool _containsAscii(Uint8List bytes, String value) {
  final List<int> needle = ascii.encode(value);
  for (int offset = 0; offset <= bytes.length - needle.length; offset++) {
    bool matches = true;
    for (int index = 0; index < needle.length; index++) {
      if (bytes[offset + index] != needle[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}
