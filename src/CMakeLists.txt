cmake_minimum_required(VERSION 3.10)
project(flutter_caesium_ffi_native NONE)

message(FATAL_ERROR
  "Build the Rust library with `dart run tool/build_native.dart` and use the "
  "platform CMake file. src/CMakeLists.txt is not a standalone C build.")
