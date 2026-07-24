#ifndef FLUTTER_CAESIUM_FFI_H
#define FLUTTER_CAESIUM_FFI_H

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/** ABI version implemented by the native library. */
#define FC_ABI_VERSION 1

/** Wrapper-owned error codes. libcaesium errors retain their original codes. */
#define FC_OK 0
#define FC_ERROR_INVALID_ARGUMENT 20001
#define FC_ERROR_INVALID_UTF8 20002
#define FC_ERROR_OUTPUT_EXISTS 20003
#define FC_ERROR_SAME_PATH 20004
#define FC_ERROR_PANIC 20999

/** Image formats accepted by conversion functions. */
typedef enum FcImageFormat {
  FC_FORMAT_JPEG = 0,
  FC_FORMAT_PNG = 1,
  FC_FORMAT_GIF = 2,
  FC_FORMAT_WEBP = 3,
  FC_FORMAT_TIFF = 4,
} FcImageFormat;

/** Fixed-width configuration shared by every operation. */
typedef struct FcOptions {
  uint8_t keep_metadata;
  uint32_t jpeg_quality;
  uint32_t jpeg_chroma_subsampling;
  uint8_t jpeg_progressive;
  uint8_t jpeg_optimize;
  uint8_t jpeg_preserve_icc;
  uint32_t png_quality;
  uint32_t png_optimization_level;
  uint8_t png_force_zopfli;
  uint8_t png_optimize;
  uint32_t gif_quality;
  uint32_t webp_quality;
  uint8_t webp_lossless;
  uint32_t tiff_compression;
  uint32_t tiff_deflate_level;
  uint32_t width;
  uint32_t height;
} FcOptions;

/** Rust-owned output buffer. Release it with fc_buffer_free. */
typedef struct FcBuffer {
  uint8_t *data;
  uint64_t length;
  uint64_t capacity;
} FcBuffer;

FFI_PLUGIN_EXPORT uint32_t fc_abi_version(void);
FFI_PLUGIN_EXPORT const char *fc_native_version(void);

FFI_PLUGIN_EXPORT uint32_t fc_compress_memory(
    const uint8_t *input_data, uint64_t input_length,
    const FcOptions *options, FcBuffer *output, char **error_message);

FFI_PLUGIN_EXPORT uint32_t fc_compress_to_size_memory(
    const uint8_t *input_data, uint64_t input_length,
    uint64_t max_output_size, uint8_t return_smallest,
    const FcOptions *options, FcBuffer *output, char **error_message);

FFI_PLUGIN_EXPORT uint32_t fc_convert_memory(
    const uint8_t *input_data, uint64_t input_length,
    uint32_t output_format, const FcOptions *options,
    FcBuffer *output, char **error_message);

FFI_PLUGIN_EXPORT uint32_t fc_compress_file(
    const char *input_path, const char *output_path,
    const FcOptions *options, char **error_message);

FFI_PLUGIN_EXPORT uint32_t fc_compress_to_size_file(
    const char *input_path, const char *output_path,
    uint64_t max_output_size, uint8_t return_smallest,
    const FcOptions *options, char **error_message);

FFI_PLUGIN_EXPORT uint32_t fc_convert_file(
    const char *input_path, const char *output_path,
    uint32_t output_format, const FcOptions *options,
    char **error_message);

FFI_PLUGIN_EXPORT void fc_buffer_free(FcBuffer *buffer);
FFI_PLUGIN_EXPORT void fc_string_free(char *string);

#ifdef __cplusplus
}
#endif

#endif
