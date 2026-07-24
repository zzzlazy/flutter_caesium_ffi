cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "flutter_caesium_ffi")
project(${PROJECT_NAME} LANGUAGES CXX)

set(NATIVE_LIBRARY
  "${CMAKE_CURRENT_SOURCE_DIR}/../native/windows/x64/flutter_caesium_ffi.dll")

if(NOT EXISTS "${NATIVE_LIBRARY}")
  message(FATAL_ERROR
    "Missing ${NATIVE_LIBRARY}. Published packages include this binary. "
    "Source builds must run: dart run tool/build_native.dart --platform windows")
endif()

add_library(flutter_caesium_ffi SHARED IMPORTED GLOBAL)
set_target_properties(flutter_caesium_ffi PROPERTIES
  IMPORTED_LOCATION "${NATIVE_LIBRARY}")

set(flutter_caesium_ffi_bundled_libraries
  "${NATIVE_LIBRARY}"
  PARENT_SCOPE)
