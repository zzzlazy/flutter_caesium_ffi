import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (data == null) {
        throw StateError('The integration test returned no comparison data.');
      }
      final String? outputPath = Platform.environment['COMPARISON_OUTPUT'];
      if (outputPath == null || outputPath.isEmpty) {
        throw StateError('COMPARISON_OUTPUT is not set.');
      }
      final String encodedOutput = data['outputBase64']! as String;
      final File output = File(outputPath);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(base64Decode(encodedOutput), flush: true);

      final Map<String, dynamic> report = Map<String, dynamic>.from(data)
        ..remove('outputBase64');
      await File('$outputPath.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
        flush: true,
      );
    },
  );
}
