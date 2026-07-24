import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  static const String _samplePng =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGP6'
      'zwAAAgcBApocMXEAAAAASUVORK5CYII=';

  String _status = 'Press the button to run libcaesium.';
  bool _running = false;

  Future<void> _compressSample() async {
    setState(() {
      _running = true;
      _status = 'Compressing on a worker isolate…';
    });
    try {
      final Uint8List input = base64Decode(_samplePng);
      final CaesiumMemoryResult result = await FlutterCaesiumFfi.compress(
        input,
        options: const CaesiumOptions(
          png: PngOptions(optimize: true),
        ),
      );
      setState(() {
        _status = '${FlutterCaesiumFfi.nativeVersion}\n'
            '${result.inputSize} → ${result.outputSize} bytes';
      });
    } on Object catch (error) {
      setState(() => _status = error.toString());
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_caesium_ffi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _running ? null : _compressSample,
                  child: const Text('Compress sample PNG'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
