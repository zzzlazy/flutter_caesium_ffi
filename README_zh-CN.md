# flutter_caesium_ffi

[English](README.md) | 简体中文

[![pub package](https://img.shields.io/pub/v/flutter_caesium_ffi.svg)](https://pub.dev/packages/flutter_caesium_ffi)
[![pub points](https://img.shields.io/pub/points/flutter_caesium_ffi)](https://pub.dev/packages/flutter_caesium_ffi/score)
[![CI](https://github.com/zzzlazy/flutter_caesium_ffi/actions/workflows/ci.yml/badge.svg)](https://github.com/zzzlazy/flutter_caesium_ffi/actions/workflows/ci.yml)
[![license: AGPL-3.0-or-later](https://img.shields.io/badge/license-AGPL--3.0--or--later-blue.svg)](LICENSE)

面向 Flutter 的快速、高质量、跨平台图片压缩库。通过统一的 Dart API，
在 Android、iOS、macOS、Windows、Linux 和 Web 上处理 JPEG、PNG、
WebP、GIF 与 TIFF，支持压缩、缩放、格式转换以及目标文件大小压缩。

原生平台通过稳定的 C ABI、Dart FFI 和 Flutter Native Assets 使用
[`libcaesium` 0.20.3](https://github.com/Lymphatus/libcaesium)；浏览器使用
[`libcaesium-wasm` 0.5.0](https://github.com/zzzlazy/libcaesium-wasm)。

Android、iOS、macOS、Windows 和 Linux 支持 JPEG、PNG、WebP、GIF
与 TIFF。Web 支持基于内存的 JPEG、PNG 和 WebP 压缩及格式转换。
原生库和 Web 资源均已随包内置，接入方无需 Rust、Cargo、npm、
手动添加脚本标签，也不需要为本包执行原生源码构建。

## 功能特性

- 基于 Caesium/libcaesium 编解码器的高质量图片压缩
- 原生平台支持 JPEG、PNG、WebP、GIF 和 TIFF
- 支持图片缩放、格式转换和元数据控制
- 尽力满足指定目标文件大小的压缩
- 内存与文件路径 API 均在 Flutter UI isolate 之外执行
- 内置原生二进制和 WebAssembly，接入方无需配置 Rust/Cargo
- 一个包覆盖 Flutter 移动端、桌面端和 Web

> **许可证提示：**本包及其内置原生代码采用 AGPL-3.0-or-later
> 许可证。分发修改或组合作品，或通过网络向用户提供相关服务时，
> 必须遵守 AGPL 及所有适用的第三方许可证义务。发布应用前请阅读
> [LICENSE](LICENSE) 和
> [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 环境要求

- Flutter 3.38.10 或更高版本
- Dart 3.10 或更高版本
- Web 端浏览器需支持 WebAssembly 和 JavaScript 模块
- Android 5.0 / API 21 或更高版本
- iOS 12.0 或更高版本
- macOS 10.14 或更高版本
- Linux x86_64，glibc 2.31 或更高版本
- Windows x64

## 安装

安装已发布的包：

```sh
flutter pub add flutter_caesium_ffi
```

也可以手动添加依赖：

```yaml
dependencies:
  flutter_caesium_ffi: ^2.0.0
```

如需跟踪默认分支上的未发布改动：

```yaml
dependencies:
  flutter_caesium_ffi:
    git:
      url: https://github.com/zzzlazy/flutter_caesium_ffi.git
      ref: main
```

然后执行 `flutter pub get`，并按正常方式构建应用。Native Assets Hook
会在不访问网络的情况下选择并打包目标平台对应的预编译库。只有修改
或重新构建原生封装时才需要 Rust。应用仍需具备 Flutter 对目标平台
要求的常规构建环境，例如 Xcode 或 Android SDK/NDK。

## 使用

内存 API 同时支持原生平台和 Web：

```dart
import 'package:flutter_caesium_ffi/flutter_caesium_ffi.dart';

final result = await FlutterCaesiumFfi.compress(
  encodedImageBytes,
  options: const CaesiumOptions(
    keepMetadata: false,
    jpeg: JpegOptions(quality: 75, progressive: true),
    resize: ResizeOptions(width: 1600),
  ),
);

print('${result.inputSize} -> ${result.outputSize} bytes');
print('native: ${FlutterCaesiumFfi.nativeVersion}');
```

公开操作包括 `compress`、`compressFile`、`compressToSize`、
`compressFileToSize`、`convert`、`convertFile` 和 `nativeVersion`。

原生图片处理在后台 isolate 中执行。Web 端会在首次调用时延迟加载
WASM 模块，目前图片处理运行在浏览器主线程。

## 平台 API 支持

| 操作 | 原生平台 | Web |
| --- | --- | --- |
| `compress` | JPEG、PNG、WebP、GIF、TIFF | JPEG、PNG、WebP |
| `compressToSize` | 支持 | 支持 |
| `convert` | 支持 | 输出 JPEG、PNG、WebP |
| 文件路径 API | 支持 | 浏览器中不可用 |

Web 使用的 libcaesium 版本较旧，因此不支持 `jpeg.preserveIcc`。
Web 端缩放尺寸上限为 999999。

## 配置与行为

`CaesiumOptions` 提供 JPEG、PNG、WebP、GIF、TIFF、缩放和元数据
相关设置。默认值与 `libcaesium` 一致：质量为 80、移除元数据、
启用渐进式 JPEG，PNG 优化级别为 3。

文件操作不会覆盖已存在的输出文件。空输入、无效质量或尺寸、
输入文件不存在、输出目录不存在，以及输入输出路径相同等问题，
都会在编码开始前失败。原生错误以
`CaesiumException(code, message)` 形式返回。

目标大小压缩采用尽力而为策略，因为部分输入或格式无法达到所有
指定大小。无法精确达到目标时，可设置 `returnSmallest: true`
以返回体积最小的候选结果。

## 内置平台

| 平台 | 内置架构 |
| --- | --- |
| Android | `arm64-v8a`、`armeabi-v7a`、`x86_64` |
| iOS | arm64 真机；arm64/x86_64 模拟器 |
| macOS | arm64、x86_64 |
| Windows | x64 MSVC |
| Linux | x86_64，glibc 2.31+ |
| Web | WebAssembly，JPEG/PNG/WebP |

## 构建原生库

普通接入方不需要执行以下步骤。贡献者需要 Rust 1.92.0 以及目标平台
SDK。以下命令用于重新生成 Native Assets Hook 所选择的预编译动态库；
Hook 本身不会调用 Cargo：

```sh
dart run tool/build_native.dart --platform macos
dart run tool/build_native.dart --platform ios
dart run tool/build_native.dart --platform android
dart run tool/build_native.dart --platform linux
dart run tool/build_native.dart --platform windows
```

Android 构建还需要 `cargo-ndk`。修改 C 头文件后，可通过以下命令
重新生成私有 Dart 绑定：

```sh
dart run ffigen --config ffigen.yaml
```

Linux 发布库使用 Zig 固定 glibc 基线：

```sh
FLUTTER_CAESIUM_LINUX_GLIBC=2.31 \
  dart run tool/build_native.dart --platform linux
```

常规 GitHub Actions 工作流会在每次 push 和 pull request 时执行
Dart 格式检查、静态分析、测试以及内置二进制校验和验证。独立的原生
工作流只会在 Rust、C ABI、绑定、原生打包或预编译二进制发生变化时
运行；版本标签和手动触发始终执行完整原生工作流。

原生工作流会构建各平台二进制，在重新构建之前使用仓库中的预编译库
验证示例应用链接，组合完整发布包，并执行
`dart pub publish --dry-run`。工作流不会自动发布到 pub.dev。
仓库内二进制的校验和记录在
[`NATIVE_CHECKSUMS.sha256`](NATIVE_CHECKSUMS.sha256)。

## 开发

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release
cargo +1.92.0 test --manifest-path rust/Cargo.toml
```

运行 Native Assets 集成测试：

```sh
flutter test test/native_integration_test.dart
```

可运行的示例应用位于 [`example`](example)。
