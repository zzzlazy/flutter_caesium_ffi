#include "../../src/flutter_caesium_ffi.h"

// Static Rust libraries are called only through dlsym. These references keep
// every exported ABI entry point alive when Xcode performs dead-code stripping.
void *flutter_caesium_ffi_force_link[] = {
    (void *)&fc_abi_version,
    (void *)&fc_native_version,
    (void *)&fc_compress_memory,
    (void *)&fc_compress_to_size_memory,
    (void *)&fc_convert_memory,
    (void *)&fc_compress_file,
    (void *)&fc_compress_to_size_file,
    (void *)&fc_convert_file,
    (void *)&fc_buffer_free,
    (void *)&fc_string_free,
};
