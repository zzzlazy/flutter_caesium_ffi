use std::ffi::{CStr, CString};
use std::fs;
use std::mem;
use std::os::raw::c_char;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::{Path, PathBuf};
use std::ptr;

use caesium::parameters::{CSParameters, ChromaSubsampling, TiffCompression, TiffDeflateLevel};
use caesium::{
    compress, compress_in_memory, compress_to_size, compress_to_size_in_memory, convert,
    convert_in_memory, SupportedFileTypes,
};

const ABI_VERSION: u32 = 1;
const NATIVE_VERSION: &[u8] = b"1.0.0+libcaesium-0.20.3\0";

const ERROR_INVALID_ARGUMENT: u32 = 20_001;
const ERROR_INVALID_UTF8: u32 = 20_002;
const ERROR_OUTPUT_EXISTS: u32 = 20_003;
const ERROR_SAME_PATH: u32 = 20_004;
const ERROR_PANIC: u32 = 20_999;

#[repr(C)]
#[derive(Clone, Copy)]
pub struct FcOptions {
    keep_metadata: u8,
    jpeg_quality: u32,
    jpeg_chroma_subsampling: u32,
    jpeg_progressive: u8,
    jpeg_optimize: u8,
    jpeg_preserve_icc: u8,
    png_quality: u32,
    png_optimization_level: u32,
    png_force_zopfli: u8,
    png_optimize: u8,
    gif_quality: u32,
    webp_quality: u32,
    webp_lossless: u8,
    tiff_compression: u32,
    tiff_deflate_level: u32,
    width: u32,
    height: u32,
}

#[repr(C)]
pub struct FcBuffer {
    data: *mut u8,
    length: u64,
    capacity: u64,
}

#[derive(Debug)]
struct BridgeError {
    code: u32,
    message: String,
}

impl BridgeError {
    fn new(code: u32, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }
}

impl From<caesium::error::CaesiumError> for BridgeError {
    fn from(value: caesium::error::CaesiumError) -> Self {
        Self::new(value.code, value.to_string())
    }
}

#[no_mangle]
pub extern "C" fn fc_abi_version() -> u32 {
    ABI_VERSION
}

#[no_mangle]
pub extern "C" fn fc_native_version() -> *const c_char {
    NATIVE_VERSION.as_ptr().cast()
}

#[no_mangle]
/// Compresses encoded image bytes.
///
/// # Safety
///
/// All non-null pointers must remain valid for the duration of this call and
/// point to values matching the public C header.
pub unsafe extern "C" fn fc_compress_memory(
    input_data: *const u8,
    input_length: u64,
    options: *const FcOptions,
    output: *mut FcBuffer,
    error_message: *mut *mut c_char,
) -> u32 {
    reset_buffer(output);
    run_guarded(error_message, || {
        let input = read_input(input_data, input_length)?;
        let parameters = read_options(options)?;
        let result = compress_in_memory(input, &parameters)?;
        store_buffer(output, result)
    })
}

#[no_mangle]
/// Compresses encoded image bytes toward a maximum output size.
///
/// # Safety
///
/// All non-null pointers must remain valid for the duration of this call and
/// point to values matching the public C header.
pub unsafe extern "C" fn fc_compress_to_size_memory(
    input_data: *const u8,
    input_length: u64,
    max_output_size: u64,
    return_smallest: u8,
    options: *const FcOptions,
    output: *mut FcBuffer,
    error_message: *mut *mut c_char,
) -> u32 {
    reset_buffer(output);
    run_guarded(error_message, || {
        if max_output_size == 0 {
            return Err(BridgeError::new(
                ERROR_INVALID_ARGUMENT,
                "max_output_size must be greater than zero",
            ));
        }
        let input = read_input(input_data, input_length)?;
        let mut parameters = read_options(options)?;
        let max_output_size = to_usize(max_output_size, "max_output_size")?;
        let result = compress_to_size_in_memory(
            input,
            &mut parameters,
            max_output_size,
            return_smallest != 0,
        )?;
        store_buffer(output, result)
    })
}

#[no_mangle]
/// Converts encoded image bytes to another format.
///
/// # Safety
///
/// All non-null pointers must remain valid for the duration of this call and
/// point to values matching the public C header.
pub unsafe extern "C" fn fc_convert_memory(
    input_data: *const u8,
    input_length: u64,
    output_format: u32,
    options: *const FcOptions,
    output: *mut FcBuffer,
    error_message: *mut *mut c_char,
) -> u32 {
    reset_buffer(output);
    run_guarded(error_message, || {
        let input = read_input(input_data, input_length)?;
        let parameters = read_options(options)?;
        let format = read_format(output_format)?;
        let result = convert_in_memory(input, &parameters, format)?;
        store_buffer(output, result)
    })
}

#[no_mangle]
/// Compresses an image from one filesystem path to another.
///
/// # Safety
///
/// Path pointers must reference valid NUL-terminated UTF-8 strings. Other
/// pointers must match the public C header and remain valid during the call.
pub unsafe extern "C" fn fc_compress_file(
    input_path: *const c_char,
    output_path: *const c_char,
    options: *const FcOptions,
    error_message: *mut *mut c_char,
) -> u32 {
    run_guarded(error_message, || {
        let (input, output) = read_file_paths(input_path, output_path)?;
        let parameters = read_options(options)?;
        compress(path_string(input)?, path_string(output)?, &parameters)?;
        Ok(())
    })
}

#[no_mangle]
/// Compresses an image file toward a maximum output size.
///
/// # Safety
///
/// Path pointers must reference valid NUL-terminated UTF-8 strings. Other
/// pointers must match the public C header and remain valid during the call.
pub unsafe extern "C" fn fc_compress_to_size_file(
    input_path: *const c_char,
    output_path: *const c_char,
    max_output_size: u64,
    return_smallest: u8,
    options: *const FcOptions,
    error_message: *mut *mut c_char,
) -> u32 {
    run_guarded(error_message, || {
        if max_output_size == 0 {
            return Err(BridgeError::new(
                ERROR_INVALID_ARGUMENT,
                "max_output_size must be greater than zero",
            ));
        }
        let (input, output) = read_file_paths(input_path, output_path)?;
        let mut parameters = read_options(options)?;
        let max_output_size = to_usize(max_output_size, "max_output_size")?;
        compress_to_size(
            path_string(input)?,
            path_string(output)?,
            &mut parameters,
            max_output_size,
            return_smallest != 0,
        )?;
        Ok(())
    })
}

#[no_mangle]
/// Converts an image file to another format.
///
/// # Safety
///
/// Path pointers must reference valid NUL-terminated UTF-8 strings. Other
/// pointers must match the public C header and remain valid during the call.
pub unsafe extern "C" fn fc_convert_file(
    input_path: *const c_char,
    output_path: *const c_char,
    output_format: u32,
    options: *const FcOptions,
    error_message: *mut *mut c_char,
) -> u32 {
    run_guarded(error_message, || {
        let (input, output) = read_file_paths(input_path, output_path)?;
        let parameters = read_options(options)?;
        let format = read_format(output_format)?;
        convert(
            path_string(input)?,
            path_string(output)?,
            &parameters,
            format,
        )?;
        Ok(())
    })
}

#[no_mangle]
/// Releases a buffer previously returned through an `FcBuffer`.
///
/// # Safety
///
/// `buffer` must be null or point to an `FcBuffer` initialized by this library.
/// A released buffer must not be freed again after its fields are modified.
pub unsafe extern "C" fn fc_buffer_free(buffer: *mut FcBuffer) {
    if buffer.is_null() {
        return;
    }
    let buffer = &mut *buffer;
    if !buffer.data.is_null() {
        drop(Vec::from_raw_parts(
            buffer.data,
            buffer.length as usize,
            buffer.capacity as usize,
        ));
    }
    buffer.data = ptr::null_mut();
    buffer.length = 0;
    buffer.capacity = 0;
}

#[no_mangle]
/// Releases an error string allocated by this library.
///
/// # Safety
///
/// `string` must be null or a pointer returned through an error-message
/// argument by this library, and it must be released at most once.
pub unsafe extern "C" fn fc_string_free(string: *mut c_char) {
    if !string.is_null() {
        drop(CString::from_raw(string));
    }
}

fn run_guarded<F>(error_message: *mut *mut c_char, operation: F) -> u32
where
    F: FnOnce() -> Result<(), BridgeError>,
{
    unsafe {
        if !error_message.is_null() {
            *error_message = ptr::null_mut();
        }
    }
    match catch_unwind(AssertUnwindSafe(operation)) {
        Ok(Ok(())) => 0,
        Ok(Err(error)) => {
            write_error(error_message, &error.message);
            error.code
        }
        Err(_) => {
            write_error(error_message, "native image operation panicked");
            ERROR_PANIC
        }
    }
}

fn write_error(error_message: *mut *mut c_char, message: &str) {
    if error_message.is_null() {
        return;
    }
    let sanitized = message.replace('\0', "\u{fffd}");
    if let Ok(message) = CString::new(sanitized) {
        unsafe {
            *error_message = message.into_raw();
        }
    }
}

unsafe fn read_input(input_data: *const u8, input_length: u64) -> Result<Vec<u8>, BridgeError> {
    if input_data.is_null() || input_length == 0 {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "input data must not be empty",
        ));
    }
    let input_length = to_usize(input_length, "input_length")?;
    Ok(std::slice::from_raw_parts(input_data, input_length).to_vec())
}

fn to_usize(value: u64, name: &str) -> Result<usize, BridgeError> {
    usize::try_from(value).map_err(|_| {
        BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            format!("{name} exceeds the addressable size on this platform"),
        )
    })
}

unsafe fn read_options(options: *const FcOptions) -> Result<CSParameters, BridgeError> {
    if options.is_null() {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "options pointer must not be null",
        ));
    }
    let options = *options;
    validate_options(options)?;

    let mut parameters = CSParameters::new();
    parameters.keep_metadata = options.keep_metadata != 0;
    parameters.jpeg.quality = options.jpeg_quality;
    parameters.jpeg.chroma_subsampling = match options.jpeg_chroma_subsampling {
        444 => ChromaSubsampling::CS444,
        422 => ChromaSubsampling::CS422,
        420 => ChromaSubsampling::CS420,
        411 => ChromaSubsampling::CS411,
        _ => ChromaSubsampling::Auto,
    };
    parameters.jpeg.progressive = options.jpeg_progressive != 0;
    parameters.jpeg.optimize = options.jpeg_optimize != 0;
    parameters.jpeg.preserve_icc = options.jpeg_preserve_icc != 0;
    parameters.png.quality = options.png_quality;
    parameters.png.optimization_level = options.png_optimization_level as u8;
    parameters.png.force_zopfli = options.png_force_zopfli != 0;
    parameters.png.optimize = options.png_optimize != 0;
    parameters.gif.quality = options.gif_quality;
    parameters.webp.quality = options.webp_quality;
    parameters.webp.lossless = options.webp_lossless != 0;
    parameters.tiff.algorithm = match options.tiff_compression {
        0 => TiffCompression::Uncompressed,
        1 => TiffCompression::Lzw,
        2 => TiffCompression::Deflate,
        _ => TiffCompression::Packbits,
    };
    parameters.tiff.deflate_level = match options.tiff_deflate_level {
        1 => TiffDeflateLevel::Fast,
        6 => TiffDeflateLevel::Balanced,
        _ => TiffDeflateLevel::Best,
    };
    parameters.width = options.width;
    parameters.height = options.height;
    Ok(parameters)
}

fn validate_options(options: FcOptions) -> Result<(), BridgeError> {
    if options.jpeg_quality > 100
        || options.png_quality > 100
        || options.webp_quality > 100
        || !(1..=100).contains(&options.gif_quality)
    {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "quality values must be between 0 and 100; GIF quality starts at 1",
        ));
    }
    if options.png_optimization_level > 6 {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "PNG optimization level must be between 0 and 6",
        ));
    }
    if !matches!(options.jpeg_chroma_subsampling, 0 | 411 | 420 | 422 | 444) {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "unsupported JPEG chroma subsampling",
        ));
    }
    if options.tiff_compression > 3 || !matches!(options.tiff_deflate_level, 1 | 6 | 9) {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "unsupported TIFF compression configuration",
        ));
    }
    Ok(())
}

fn read_format(value: u32) -> Result<SupportedFileTypes, BridgeError> {
    match value {
        0 => Ok(SupportedFileTypes::Jpeg),
        1 => Ok(SupportedFileTypes::Png),
        2 => Ok(SupportedFileTypes::Gif),
        3 => Ok(SupportedFileTypes::WebP),
        4 => Ok(SupportedFileTypes::Tiff),
        _ => Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "unsupported output format",
        )),
    }
}

unsafe fn read_file_paths(
    input_path: *const c_char,
    output_path: *const c_char,
) -> Result<(PathBuf, PathBuf), BridgeError> {
    let input = read_path(input_path)?;
    let output = read_path(output_path)?;
    let input_absolute = fs::canonicalize(&input).map_err(|error| {
        BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            format!("cannot access input file: {error}"),
        )
    })?;
    let output_parent = output
        .parent()
        .filter(|parent| !parent.as_os_str().is_empty())
        .unwrap_or_else(|| Path::new("."));
    let output_name = output
        .file_name()
        .ok_or_else(|| BridgeError::new(ERROR_INVALID_ARGUMENT, "output path has no file name"))?;
    let output_absolute = fs::canonicalize(output_parent)
        .map_err(|error| {
            BridgeError::new(
                ERROR_INVALID_ARGUMENT,
                format!("cannot access output directory: {error}"),
            )
        })?
        .join(output_name);
    if input_absolute == output_absolute {
        return Err(BridgeError::new(
            ERROR_SAME_PATH,
            "input and output paths must be different",
        ));
    }
    if output.exists() {
        return Err(BridgeError::new(
            ERROR_OUTPUT_EXISTS,
            "output file already exists",
        ));
    }
    Ok((input_absolute, output_absolute))
}

unsafe fn read_path(path: *const c_char) -> Result<PathBuf, BridgeError> {
    if path.is_null() {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "path pointer must not be null",
        ));
    }
    let value = CStr::from_ptr(path)
        .to_str()
        .map_err(|_| BridgeError::new(ERROR_INVALID_UTF8, "path is not valid UTF-8"))?;
    if value.is_empty() {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "path must not be empty",
        ));
    }
    Ok(PathBuf::from(value))
}

fn path_string(path: PathBuf) -> Result<String, BridgeError> {
    path.into_os_string()
        .into_string()
        .map_err(|_| BridgeError::new(ERROR_INVALID_UTF8, "path is not valid UTF-8"))
}

unsafe fn reset_buffer(output: *mut FcBuffer) {
    if !output.is_null() {
        (*output).data = ptr::null_mut();
        (*output).length = 0;
        (*output).capacity = 0;
    }
}

fn store_buffer(output: *mut FcBuffer, mut bytes: Vec<u8>) -> Result<(), BridgeError> {
    if output.is_null() {
        return Err(BridgeError::new(
            ERROR_INVALID_ARGUMENT,
            "output buffer pointer must not be null",
        ));
    }
    let buffer = FcBuffer {
        data: bytes.as_mut_ptr(),
        length: bytes.len() as u64,
        capacity: bytes.capacity() as u64,
    };
    mem::forget(bytes);
    unsafe {
        *output = buffer;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE_PNG: &[u8] = &[
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 2, 0, 0, 0, 2, 8, 2,
        0, 0, 0, 253, 212, 154, 115, 0, 0, 0, 20, 73, 68, 65, 84, 120, 156, 99, 248, 207, 192, 192,
        0, 194, 12, 255, 255, 255, 103, 0, 0, 30, 239, 4, 252, 163, 200, 180, 247, 0, 0, 0, 0, 73,
        69, 78, 68, 174, 66, 96, 130,
    ];

    fn default_options() -> FcOptions {
        FcOptions {
            keep_metadata: 0,
            jpeg_quality: 80,
            jpeg_chroma_subsampling: 0,
            jpeg_progressive: 1,
            jpeg_optimize: 0,
            jpeg_preserve_icc: 1,
            png_quality: 80,
            png_optimization_level: 3,
            png_force_zopfli: 0,
            png_optimize: 0,
            gif_quality: 80,
            webp_quality: 80,
            webp_lossless: 0,
            tiff_compression: 2,
            tiff_deflate_level: 6,
            width: 0,
            height: 0,
        }
    }

    #[test]
    fn abi_and_version_are_stable() {
        assert_eq!(fc_abi_version(), 1);
        let value = unsafe { CStr::from_ptr(fc_native_version()) };
        assert_eq!(value.to_str().unwrap(), "1.0.0+libcaesium-0.20.3");
    }

    #[test]
    fn defaults_map_to_libcaesium() {
        let options = default_options();
        let parameters = unsafe { read_options(&options) }.unwrap();
        assert_eq!(parameters.jpeg.quality, 80);
        assert!(parameters.jpeg.progressive);
        assert_eq!(parameters.png.optimization_level, 3);
        assert_eq!(parameters.gif.quality, 80);
        assert_eq!(parameters.webp.quality, 80);
        assert_eq!(parameters.width, 0);
        assert_eq!(parameters.height, 0);
    }

    #[test]
    fn rejects_invalid_options() {
        let mut options = default_options();
        options.png_optimization_level = 7;
        assert!(validate_options(options).is_err());

        let mut options = default_options();
        options.gif_quality = 0;
        assert!(validate_options(options).is_err());
    }

    #[test]
    fn buffer_round_trip_releases_memory() {
        let mut output = FcBuffer {
            data: ptr::null_mut(),
            length: 0,
            capacity: 0,
        };
        store_buffer(&mut output, vec![1, 2, 3]).unwrap();
        assert_eq!(
            unsafe { std::slice::from_raw_parts(output.data, output.length as usize) },
            &[1, 2, 3]
        );
        unsafe { fc_buffer_free(&mut output) };
        assert!(output.data.is_null());
        assert_eq!(output.length, 0);
    }

    #[test]
    fn converts_and_compresses_every_supported_format() {
        let parameters = CSParameters::new();
        let formats = [
            SupportedFileTypes::Jpeg,
            SupportedFileTypes::Gif,
            SupportedFileTypes::WebP,
            SupportedFileTypes::Tiff,
        ];

        for format in formats {
            let converted = convert_in_memory(SAMPLE_PNG.to_vec(), &parameters, format).unwrap();
            assert!(!converted.is_empty());
            let compressed = compress_in_memory(converted, &parameters).unwrap();
            assert!(!compressed.is_empty());
        }

        let compressed_png = compress_in_memory(SAMPLE_PNG.to_vec(), &parameters).unwrap();
        assert!(compressed_png.starts_with(&[137, 80, 78, 71]));
    }

    #[test]
    fn resizes_and_compresses_to_a_target_size() {
        let mut parameters = CSParameters::new();
        parameters.width = 2;
        parameters.height = 3;
        let resized = compress_in_memory(SAMPLE_PNG.to_vec(), &parameters).unwrap();
        assert_eq!(u32::from_be_bytes(resized[16..20].try_into().unwrap()), 2);
        assert_eq!(u32::from_be_bytes(resized[20..24].try_into().unwrap()), 3);

        let mut target_parameters = CSParameters::new();
        let targeted =
            compress_to_size_in_memory(SAMPLE_PNG.to_vec(), &mut target_parameters, 128, true)
                .unwrap();
        assert!(!targeted.is_empty());
    }

    #[test]
    fn c_abi_reports_and_releases_errors() {
        let options = default_options();
        let mut output = FcBuffer {
            data: ptr::null_mut(),
            length: 0,
            capacity: 0,
        };
        let mut error_message = ptr::null_mut();
        let code = unsafe {
            fc_compress_memory(ptr::null(), 0, &options, &mut output, &mut error_message)
        };

        assert_eq!(code, ERROR_INVALID_ARGUMENT);
        assert!(!error_message.is_null());
        unsafe { fc_string_free(error_message) };
    }
}
