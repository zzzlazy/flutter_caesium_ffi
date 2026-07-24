import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 4) {
    stderr.writeln(
      'Usage: dart run tool/compress_fixture.dart '
      '<input> <output> <platform> <quality>',
    );
    exitCode = 64;
    return;
  }

  final String inputPath = arguments[0];
  final String outputPath = arguments[1];
  final String platform = arguments[2];
  final int quality = int.parse(arguments[3]);
  if (quality < 0 || quality > 100) {
    throw RangeError.range(quality, 0, 100, 'quality');
  }

  final Uint8List input = await File(inputPath).readAsBytes();
  final CaesiumMemoryResult result = await FlutterCaesiumFfi.compress(
    input,
    options: CaesiumOptions(
      keepMetadata: false,
      jpeg: JpegOptions(
        quality: quality,
        progressive: true,
        optimize: false,
        preserveIcc: false,
      ),
    ),
  );

  final File output = File(outputPath);
  await output.parent.create(recursive: true);
  await output.writeAsBytes(result.bytes, flush: true);
  await File('$outputPath.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'platform': platform,
      'quality': quality,
      'version': FlutterCaesiumFfi.nativeVersion,
      'inputSize': result.inputSize,
      'outputSize': result.outputSize,
    }),
    flush: true,
  );
}
