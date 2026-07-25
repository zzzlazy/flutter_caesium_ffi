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
    'macos' ||
    'ios' ||
    'android' ||
    'linux' ||
    'windows' => <String>[requested],
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
  const Map<String, String> targets = <String, String>{
    'aarch64-apple-darwin': 'arm64',
    'x86_64-apple-darwin': 'x64',
  };
  for (final MapEntry<String, String> target in targets.entries) {
    await _cargoBuild(
      root,
      target.key,
      environment: const <String, String>{'MACOSX_DEPLOYMENT_TARGET': '10.14'},
    );
    await _copyAppleDynamicLibrary(
      root,
      rustTarget: target.key,
      platform: 'macos',
      destinationTarget: target.value,
    );
  }
}

Future<void> _buildIos(Directory root) async {
  const Map<String, String> targets = <String, String>{
    'aarch64-apple-ios': 'arm64',
    'aarch64-apple-ios-sim': 'arm64-simulator',
    'x86_64-apple-ios': 'x64-simulator',
  };
  const Map<String, String> environment = <String, String>{
    'IPHONEOS_DEPLOYMENT_TARGET': '12.0',
  };
  for (final MapEntry<String, String> target in targets.entries) {
    await _cargoBuild(root, target.key, environment: environment);
    await _copyAppleDynamicLibrary(
      root,
      rustTarget: target.key,
      platform: 'ios',
      destinationTarget: target.value,
    );
  }
}

Future<void> _buildAndroid(Directory root) async {
  final String output = _join(root.path, 'native', 'android');
  await _run('cargo', <String>[
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
  ], workingDirectory: _join(root.path, 'rust'));
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
  return _run('cargo', <String>[
    '+1.92.0',
    'build',
    '--release',
    '--manifest-path',
    _join(root.path, 'rust', 'Cargo.toml'),
    '--target',
    target,
  ], environment: environment);
}

Future<void> _copyAppleDynamicLibrary(
  Directory root, {
  required String rustTarget,
  required String platform,
  required String destinationTarget,
}) async {
  final String source = _join(
    root.path,
    'rust',
    'target',
    rustTarget,
    'release',
    'lib$_libraryBase.dylib',
  );
  final String destination = _join(
    root.path,
    'native',
    platform,
    destinationTarget,
    'lib$_libraryBase.dylib',
  );
  await File(destination).parent.create(recursive: true);
  await File(source).copy(destination);
  await _run('install_name_tool', <String>[
    '-id',
    '@rpath/lib$_libraryBase.dylib',
    destination,
  ]);
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
      executable,
      arguments,
      'Native build failed.',
      result,
    );
  }
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
  String? fifth,
  String? sixth,
  String? seventh,
]) {
  return <String>[
    first,
    second,
    ?third,
    ?fourth,
    ?fifth,
    ?sixth,
    ?seventh,
  ].join(Platform.pathSeparator);
}
