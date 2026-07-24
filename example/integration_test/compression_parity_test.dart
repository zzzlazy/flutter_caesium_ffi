import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const int _quality =
    int.fromEnvironment('COMPARISON_QUALITY', defaultValue: 62);
const String _platform =
    String.fromEnvironment('COMPARISON_PLATFORM', defaultValue: 'unknown');

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compresses the parity fixture', (WidgetTester tester) async {
    final ByteData inputData =
        await rootBundle.load('assets/comparison/input.jpeg');
    final Uint8List input = inputData.buffer.asUint8List(
      inputData.offsetInBytes,
      inputData.lengthInBytes,
    );
    final CaesiumMemoryResult result = await FlutterCaesiumFfi.compress(
      input,
      options: const CaesiumOptions(
        keepMetadata: false,
        jpeg: JpegOptions(
          quality: _quality,
          progressive: true,
          optimize: false,
          preserveIcc: false,
        ),
      ),
    );

    expect(result.bytes, isNotEmpty);
    expect(result.outputSize, result.bytes.length);
    expect(result.bytes[0], 0xff);
    expect(result.bytes[1], 0xd8);

    binding.reportData = <String, dynamic>{
      'platform': _platform,
      'quality': _quality,
      'version': FlutterCaesiumFfi.nativeVersion,
      'inputSize': result.inputSize,
      'outputSize': result.outputSize,
      'outputBase64': base64Encode(result.bytes),
    };
  });
}
