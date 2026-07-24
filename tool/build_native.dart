import 'dart:io';

const String _libraryBase = 'flutter_caesium_ffi';

Future<void> main(List<String> arguments) async {
  final Directory root = Directory.current;
  if (!File(_join(root.path, 'pubspec.yaml')).existsSync()) {
    stderr.writeln('Run this command from the package root.');
    exitCode = 64;
    return;
  }

  final String requested = _readPlatform(arguments);
  final List<String> platforms = switch (requested) {
    'host' => <String>[_hostPlatform()],
    'all-apple' => <String>['macos', 'ios'],
    'macos' || 'ios' || 'android' || 'linux' || 'windows' => <String>[
        requested
      ],
    _ => throw ArgumentError.value(requested, '--platform'),
  };

  for (final String platform in platforms) {
    stdout.writeln('Building $_libraryBase for $platform...');
    switch (platform) {
      case 'macos':
        await _buildMacos(root);
      case 'ios':
        await _buildIos(root);
      case 'android':
        await _buildAndroid(root);
      case 'linux':
        await _buildLinux(root);
      case 'windows':
        await _buildWindows(root);
    }
  }
}

String _readPlatform(List<String> arguments) {
  for (int index = 0; index < arguments.length; index++) {
    final String argument = arguments[index];
    if (argument == '--platform' && index + 1 < arguments.length) {
      return arguments[index + 1];
    }
    if (argument.startsWith('--platform=')) {
      return argument.substring('--platform='.length);
    }
  }
  return 'host';
}

String _hostPlatform() {
  if (Platform.isMacOS) return 'macos';
  if (Platform.isLinux) return 'linux';
  if (Platform.isWindows) return 'windows';
  throw UnsupportedError('Unsupported build host: ${Platform.operatingSystem}');
}

Future<void> _buildMacos(Directory root) async {
  const List<String> targets = <String>[
    'aarch64-apple-darwin',
    'x86_64-apple-darwin',
  ];
  for (final String target in targets) {
    await _cargoBuild(
      root,
      target,
      environment: const <String, String>{
        'MACOSX_DEPLOYMENT_TARGET': '10.14',
      },
    );
  }

  final Directory temporary =
      await Directory.systemTemp.createTemp('flutter_caesium_macos_');
  try {
    final String universal = _join(temporary.path, 'lib$_libraryBase.a');
    final String headers = await _copyPublicHeaders(root, temporary);
    await _run('lipo', <String>[
      '-create',
      _rustLibrary(root, targets[0]),
      _rustLibrary(root, targets[1]),
      '-output',
      universal,
    ]);
    final String output = _join(
      root.path,
      'macos',
      'Frameworks',
      '$_libraryBase.xcframework',
    );
    await _replaceDirectory(output);
    await _run('xcodebuild', <String>[
      '-create-xcframework',
      '-library',
      universal,
      '-headers',
      headers,
      '-output',
      output,
    ]);
  } finally {
    await temporary.delete(recursive: true);
  }
}

Future<void> _buildIos(Directory root) async {
  const String deviceTarget = 'aarch64-apple-ios';
  const List<String> simulatorTargets = <String>[
    'aarch64-apple-ios-sim',
    'x86_64-apple-ios',
  ];
  const Map<String, String> environment = <String, String>{
    'IPHONEOS_DEPLOYMENT_TARGET': '12.0',
  };
  await _cargoBuild(root, deviceTarget, environment: environment);
  for (final String target in simulatorTargets) {
    await _cargoBuild(root, target, environment: environment);
  }

  final Directory temporary =
      await Directory.systemTemp.createTemp('flutter_caesium_ios_');
  try {
    final String simulator = _join(temporary.path, 'lib$_libraryBase.a');
    final String headers = await _copyPublicHeaders(root, temporary);
    await _run('lipo', <String>[
      '-create',
      _rustLibrary(root, simulatorTargets[0]),
      _rustLibrary(root, simulatorTargets[1]),
      '-output',
      simulator,
    ]);
    final String output = _join(
      root.path,
      'ios',
      'Frameworks',
      '$_libraryBase.xcframework',
    );
    await _replaceDirectory(output);
    await _run('xcodebuild', <String>[
      '-create-xcframework',
      '-library',
      _rustLibrary(root, deviceTarget),
      '-headers',
      headers,
      '-library',
      simulator,
      '-headers',
      headers,
      '-output',
      output,
    ]);
  } finally {
    await temporary.delete(recursive: true);
  }
}

Future<void> _buildAndroid(Directory root) async {
  final String output = _join(root.path, 'native', 'android');
  await _run(
      'cargo',
      <String>[
        '+1.92.0',
        'ndk',
        '-p',
        '21',
        '-t',
        'arm64-v8a',
        '-t',
        'armeabi-v7a',
        '-t',
        'x86_64',
        '-o',
        output,
        'build',
        '--release',
      ],
      workingDirectory: _join(root.path, 'rust'));
}

Future<void> _buildLinux(Directory root) async {
  if (Platform.version.contains('linux') == false && !Platform.isLinux) {
    throw UnsupportedError('Linux binaries must be built on Linux.');
  }
  final String? glibcVersion =
      Platform.environment['FLUTTER_CAESIUM_LINUX_GLIBC'];
  if (glibcVersion == null || glibcVersion.isEmpty) {
    await _cargoBuild(root, 'x86_64-unknown-linux-gnu');
  } else {
    await _run(
      'cargo',
      <String>[
        '+1.92.0',
        'zigbuild',
        '--release',
        '--manifest-path',
        _join(root.path, 'rust', 'Cargo.toml'),
        '--target',
        'x86_64-unknown-linux-gnu.$glibcVersion',
      ],
      environment: const <String, String>{
        // Zig 0.13's Clang rejects libdeflate's AVX-512 target functions with
        // an erroneous "without evex512 enabled changes the ABI" diagnostic.
        // Keep the portable and AVX2 paths while omitting only those optional
        // dispatch implementations from the glibc-baseline build.
        'CFLAGS_x86_64_unknown_linux_gnu':
            '-DLIBDEFLATE_ASSEMBLER_DOES_NOT_SUPPORT_VPCLMULQDQ '
                '-DLIBDEFLATE_ASSEMBLER_DOES_NOT_SUPPORT_AVX512VNNI '
                '-DLIBDEFLATE_ASSEMBLER_DOES_NOT_SUPPORT_AVX_VNNI',
      },
    );
  }
  final File source = File(
    _join(
      root.path,
      'rust',
      'target',
      'x86_64-unknown-linux-gnu',
      'release',
      'lib$_libraryBase.so',
    ),
  );
  await source.copy(
    _join(root.path, 'native', 'linux', 'x64', 'lib$_libraryBase.so'),
  );
}

Future<void> _buildWindows(Directory root) async {
  if (!Platform.isWindows) {
    throw UnsupportedError('Windows binaries must be built on Windows.');
  }
  await _cargoBuild(root, 'x86_64-pc-windows-msvc');
  final File source = File(
    _join(
      root.path,
      'rust',
      'target',
      'x86_64-pc-windows-msvc',
      'release',
      '$_libraryBase.dll',
    ),
  );
  await source.copy(
    _join(root.path, 'native', 'windows', 'x64', '$_libraryBase.dll'),
  );
}

Future<void> _cargoBuild(
  Directory root,
  String target, {
  Map<String, String>? environment,
}) {
  return _run(
    'cargo',
    <String>[
      '+1.92.0',
      'build',
      '--release',
      '--manifest-path',
      _join(root.path, 'rust', 'Cargo.toml'),
      '--target',
      target,
    ],
    environment: environment,
  );
}

String _rustLibrary(Directory root, String target) {
  return _join(
    root.path,
    'rust',
    'target',
    target,
    'release',
    'lib$_libraryBase.a',
  );
}

Future<void> _replaceDirectory(String path) async {
  final Directory directory = Directory(path);
  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}

Future<String> _copyPublicHeaders(
  Directory root,
  Directory temporary,
) async {
  final Directory headers = Directory(_join(temporary.path, 'Headers'));
  await headers.create();
  await File(_join(root.path, 'src', 'flutter_caesium_ffi.h')).copy(
    _join(headers.path, 'flutter_caesium_ffi.h'),
  );
  return headers.path;
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  Map<String, String>? environment,
  String? workingDirectory,
}) async {
  stdout.writeln('\$ $executable ${arguments.join(' ')}');
  final Process process = await Process.start(
    executable,
    arguments,
    environment: environment,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  final int result = await process.exitCode;
  if (result != 0) {
    throw ProcessException(
        executable, arguments, 'Native build failed.', result);
  }
}

String _join(String first, String second,
    [String? third,
    String? fourth,
    String? fifth,
    String? sixth,
    String? seventh]) {
  return <String>[
    first,
    second,
    if (third != null) third,
    if (fourth != null) fourth,
    if (fifth != null) fifth,
    if (sixth != null) sixth,
    if (seventh != null) seventh,
  ].join(Platform.pathSeparator);
}
