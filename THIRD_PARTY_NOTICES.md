# Third-party notices

`flutter_caesium_ffi` links `libcaesium` 0.20.3 and its Rust/native
dependency graph into the distributed binaries. The exact, reproducible
dependency set is pinned in [`rust/Cargo.lock`](rust/Cargo.lock).

The combined package is distributed under **AGPL-3.0-or-later** because the
native dependency graph includes `gifski` (AGPL-3.0-or-later) and
`imagequant` (GPL-3.0-or-later). Redistributors must retain applicable
copyright and license notices and make Corresponding Source available as
required by the AGPL/GPL.

The dependency metadata below was generated from the pinned Cargo graph.
Where a crate offers multiple licenses, consult that project's source before
choosing the applicable terms.

| Component | Version | Declared license | Project/source |
| --- | --- | --- | --- |
| adler2 | 2.0.1 | 0BSD OR MIT OR Apache-2.0 | https://github.com/oyvindln/adler2 |
| anstream | 1.0.0 | MIT OR Apache-2.0 | https://github.com/rust-cli/anstyle.git |
| anstyle | 1.0.14 | MIT OR Apache-2.0 | https://github.com/rust-cli/anstyle.git |
| anstyle-parse | 1.0.0 | MIT OR Apache-2.0 | https://github.com/rust-cli/anstyle.git |
| anstyle-query | 1.1.5 | MIT OR Apache-2.0 | https://github.com/rust-cli/anstyle.git |
| anstyle-wincon | 3.0.11 | MIT OR Apache-2.0 | https://github.com/rust-cli/anstyle.git |
| arrayvec | 0.7.8 | MIT OR Apache-2.0 | https://github.com/bluss/arrayvec |
| autocfg | 1.5.1 | Apache-2.0 OR MIT | https://github.com/cuviper/autocfg |
| bitflags | 2.13.1 | MIT OR Apache-2.0 | https://github.com/bitflags/bitflags |
| bitvec | 1.1.1 | MIT | https://github.com/bitvecto-rs/bitvec |
| bumpalo | 3.20.3 | MIT OR Apache-2.0 | https://github.com/fitzgen/bumpalo |
| bytemuck | 1.25.2 | Zlib OR Apache-2.0 OR MIT | https://github.com/Lokathor/bytemuck |
| byteorder | 1.5.0 | Unlicense OR MIT | https://github.com/BurntSushi/byteorder |
| byteorder-lite | 0.1.0 | Unlicense OR MIT | https://github.com/image-rs/byteorder-lite |
| bytes | 1.12.1 | MIT | https://github.com/tokio-rs/bytes |
| cc | 1.3.0 | MIT OR Apache-2.0 | https://github.com/rust-lang/cc-rs |
| cfb | 0.7.3 | MIT | https://github.com/mdsteele/rust-cfb |
| cfg-if | 1.0.4 | MIT OR Apache-2.0 | https://github.com/rust-lang/cfg-if |
| clap | 4.6.4 | MIT OR Apache-2.0 | https://github.com/clap-rs/clap |
| clap_builder | 4.6.2 | MIT OR Apache-2.0 | https://github.com/clap-rs/clap |
| clap_lex | 1.1.0 | MIT OR Apache-2.0 | https://github.com/clap-rs/clap |
| color_quant | 1.1.0 | MIT | https://github.com/image-rs/color_quant.git |
| colorchoice | 1.0.5 | MIT OR Apache-2.0 | https://github.com/rust-cli/anstyle.git |
| crc32fast | 1.5.0 | MIT OR Apache-2.0 | https://github.com/srijs/rust-crc32fast |
| crossbeam-channel | 0.5.16 | MIT OR Apache-2.0 | https://github.com/crossbeam-rs/crossbeam |
| crossbeam-deque | 0.8.7 | MIT OR Apache-2.0 | https://github.com/crossbeam-rs/crossbeam |
| crossbeam-epoch | 0.9.20 | MIT OR Apache-2.0 | https://github.com/crossbeam-rs/crossbeam |
| crossbeam-utils | 0.8.22 | MIT OR Apache-2.0 | https://github.com/crossbeam-rs/crossbeam |
| crunchy | 0.2.4 | MIT | https://github.com/eira-fransham/crunchy |
| dunce | 1.0.5 | CC0-1.0 OR MIT-0 OR Apache-2.0 | https://gitlab.com/kornelski/dunce |
| either | 1.16.0 | MIT OR Apache-2.0 | https://github.com/rayon-rs/either |
| equivalent | 1.0.2 | Apache-2.0 OR MIT | https://github.com/indexmap-rs/equivalent |
| fax | 0.2.7 | MIT | https://github.com/pdf-rs/fax |
| fdeflate | 0.3.7 | MIT OR Apache-2.0 | https://github.com/image-rs/fdeflate |
| filetime | 0.2.29 | MIT/Apache-2.0 | https://github.com/alexcrichton/filetime |
| find-msvc-tools | 0.1.9 | MIT OR Apache-2.0 | https://github.com/rust-lang/cc-rs |
| flate2 | 1.1.9 | MIT OR Apache-2.0 | https://github.com/rust-lang/flate2-rs |
| fnv | 1.0.7 | Apache-2.0 / MIT | https://github.com/servo/rust-fnv |
| funty | 2.0.0 | MIT | https://github.com/myrrlyn/funty |
| futures-core | 0.3.33 | MIT OR Apache-2.0 | https://github.com/rust-lang/futures-rs |
| futures-task | 0.3.33 | MIT OR Apache-2.0 | https://github.com/rust-lang/futures-rs |
| futures-util | 0.3.33 | MIT OR Apache-2.0 | https://github.com/rust-lang/futures-rs |
| getrandom | 0.4.3 | MIT OR Apache-2.0 | https://github.com/rust-random/getrandom |
| gif | 0.13.3 | MIT OR Apache-2.0 | https://github.com/image-rs/image-gif |
| gif | 0.14.2 | MIT OR Apache-2.0 | https://github.com/image-rs/image-gif |
| gif-dispose | 5.0.1 | MIT OR Apache-2.0 | https://github.com/kornelski/image-gif-dispose.git |
| gifski | 1.34.0 | AGPL-3.0-or-later | https://github.com/ImageOptim/gifski |
| glob | 0.3.4 | MIT OR Apache-2.0 | https://github.com/rust-lang/glob |
| half | 2.7.1 | MIT OR Apache-2.0 | https://github.com/VoidStarKat/half-rs |
| hashbrown | 0.17.1 | MIT OR Apache-2.0 | https://github.com/rust-lang/hashbrown |
| image | 0.25.10 | MIT OR Apache-2.0 | https://github.com/image-rs/image |
| image-webp | 0.2.4 | MIT OR Apache-2.0 | https://github.com/image-rs/image-webp |
| imagequant | 4.4.1 | GPL-3.0-or-later | https://github.com/ImageOptim/libimagequant |
| img-parts | 0.4.0 | MIT OR Apache-2.0 | https://github.com/paolobarbolini/img-parts |
| imgref | 1.12.2 | CC0-1.0 OR Apache-2.0 | https://github.com/kornelski/imgref |
| indexmap | 2.14.0 | Apache-2.0 OR MIT | https://github.com/indexmap-rs/indexmap |
| infer | 0.19.0 | MIT | https://github.com/bojand/infer |
| is_terminal_polyfill | 1.70.2 | MIT OR Apache-2.0 | https://github.com/polyfill-rs/is_terminal_polyfill |
| jobserver | 0.1.35 | MIT OR Apache-2.0 | https://github.com/rust-lang/jobserver-rs |
| jpeg-decoder | 0.3.2 | MIT OR Apache-2.0 | https://github.com/image-rs/jpeg-decoder |
| js-sys | 0.3.103 | MIT OR Apache-2.0 | https://github.com/wasm-bindgen/wasm-bindgen/tree/master/crates/js-sys |
| kamadak-exif | 0.6.1 | BSD-2-Clause | https://github.com/kamadak/exif-rs |
| libc | 0.2.189 | MIT OR Apache-2.0 | https://github.com/rust-lang/libc |
| libcaesium | 0.20.3 | Apache-2.0 | https://github.com/Lymphatus/libcaesium |
| libdeflate-sys | 1.25.2 | Apache-2.0 | https://github.com/libdeflater/libdeflater |
| libdeflater | 1.25.2 | Apache-2.0 | https://github.com/libdeflater/libdeflater |
| libwebp-sys | 0.9.5 | MIT | https://github.com/NoXF/libwebp-sys |
| lodepng | 3.12.2 | Zlib | https://github.com/kornelski/lodepng-rust.git |
| log | 0.4.33 | MIT OR Apache-2.0 | https://github.com/rust-lang/log |
| loop9 | 0.1.5 | MIT | https://gitlab.com/kornelski/loop9.git |
| miniz_oxide | 0.8.9 | MIT OR Zlib OR Apache-2.0 | https://github.com/Frommi/miniz_oxide/tree/master/miniz_oxide |
| moxcms | 0.8.1 | BSD-3-Clause OR Apache-2.0 | https://github.com/awxkee/moxcms.git |
| mozjpeg-sys | 2.2.1 | IJG AND Zlib AND BSD-3-Clause | https://github.com/kornelski/mozjpeg-sys.git |
| mutate_once | 0.1.2 | BSD-2-Clause | https://github.com/kamadak/mutate_once-rs |
| nasm-rs | 0.3.2 | MIT OR Apache-2.0 | https://github.com/medek/nasm-rs |
| natord | 1.0.9 | MIT | https://github.com/lifthrasiir/rust-natord |
| num-traits | 0.2.19 | MIT OR Apache-2.0 | https://github.com/rust-num/num-traits |
| once_cell | 1.21.4 | MIT OR Apache-2.0 | https://github.com/matklad/once_cell |
| once_cell_polyfill | 1.70.2 | MIT OR Apache-2.0 | https://github.com/polyfill-rs/once_cell_polyfill |
| ordered-channel | 1.2.0 | MIT OR Apache-2.0 | https://gitlab.com/kornelski/ordered-channel |
| oxipng | 9.1.5 | MIT | https://github.com/shssoichiro/oxipng |
| pbr | 1.1.1 | MIT | https://github.com/a8m/pb |
| pin-project-lite | 0.2.17 | Apache-2.0 OR MIT | https://github.com/taiki-e/pin-project-lite |
| png | 0.18.1 | MIT OR Apache-2.0 | https://github.com/image-rs/image-png |
| proc-macro2 | 1.0.107 | MIT OR Apache-2.0 | https://github.com/dtolnay/proc-macro2 |
| pxfm | 0.1.30 | BSD-3-Clause OR Apache-2.0 | https://github.com/awxkee/pxfm |
| quick-error | 2.0.1 | MIT/Apache-2.0 | http://github.com/tailhook/quick-error |
| quote | 1.0.47 | MIT OR Apache-2.0 | https://github.com/dtolnay/quote |
| r-efi | 6.0.0 | MIT OR Apache-2.0 OR LGPL-2.1-or-later | https://github.com/r-efi/r-efi |
| radium | 0.7.0 | MIT | https://github.com/bitvecto-rs/radium |
| rayon | 1.12.0 | MIT OR Apache-2.0 | https://github.com/rayon-rs/rayon |
| rayon-core | 1.13.0 | MIT OR Apache-2.0 | https://github.com/rayon-rs/rayon |
| resize | 0.8.9 | MIT | https://github.com/PistonDevelopers/resize.git |
| rgb | 0.8.53 | MIT | https://github.com/kornelski/rust-rgb |
| rustc-hash | 2.1.3 | Apache-2.0 OR MIT | https://github.com/rust-lang/rustc-hash |
| rustversion | 1.0.23 | MIT OR Apache-2.0 | https://github.com/dtolnay/rustversion |
| shlex | 2.0.1 | MIT OR Apache-2.0 | https://github.com/comex/rust-shlex |
| simd-adler32 | 0.3.10 | MIT | https://github.com/mcountryman/simd-adler32 |
| slab | 0.4.12 | MIT | https://github.com/tokio-rs/slab |
| strsim | 0.11.1 | MIT | https://github.com/rapidfuzz/strsim-rs |
| syn | 2.0.119 | MIT OR Apache-2.0 | https://github.com/dtolnay/syn |
| tap | 1.0.1 | MIT | https://github.com/myrrlyn/tap |
| thread_local | 1.1.10 | MIT OR Apache-2.0 | https://github.com/Amanieu/thread_local-rs |
| tiff | 0.11.3 | MIT | https://github.com/image-rs/image-tiff |
| tiff | 0.9.1 | MIT | https://github.com/image-rs/image-tiff |
| unicode-ident | 1.0.24 | (MIT OR Apache-2.0) AND Unicode-3.0 | https://github.com/dtolnay/unicode-ident |
| utf8parse | 0.2.2 | Apache-2.0 OR MIT | https://github.com/alacritty/vte |
| uuid | 1.24.0 | Apache-2.0 OR MIT | https://github.com/uuid-rs/uuid |
| wasm-bindgen | 0.2.126 | MIT OR Apache-2.0 | https://github.com/wasm-bindgen/wasm-bindgen |
| wasm-bindgen-macro | 0.2.126 | MIT OR Apache-2.0 | https://github.com/wasm-bindgen/wasm-bindgen/tree/master/crates/macro |
| wasm-bindgen-macro-support | 0.2.126 | MIT OR Apache-2.0 | https://github.com/wasm-bindgen/wasm-bindgen/tree/master/crates/macro-support |
| wasm-bindgen-shared | 0.2.126 | MIT OR Apache-2.0 | https://github.com/wasm-bindgen/wasm-bindgen/tree/master/crates/shared |
| webp | 0.3.1 | MIT OR Apache-2.0 | https://github.com/jaredforth/webp.git |
| weezl | 0.1.12 | MIT OR Apache-2.0 | https://github.com/image-rs/weezl |
| wild | 2.2.1 | Apache-2.0 OR MIT | https://gitlab.com/kornelski/wild |
| winapi | 0.3.9 | MIT/Apache-2.0 | https://github.com/retep998/winapi-rs |
| winapi-i686-pc-windows-gnu | 0.4.0 | MIT/Apache-2.0 | https://github.com/retep998/winapi-rs |
| winapi-x86_64-pc-windows-gnu | 0.4.0 | MIT/Apache-2.0 | https://github.com/retep998/winapi-rs |
| windows-link | 0.2.1 | MIT OR Apache-2.0 | https://github.com/microsoft/windows-rs |
| windows-sys | 0.61.2 | MIT OR Apache-2.0 | https://github.com/microsoft/windows-rs |
| wyz | 0.5.1 | MIT | https://github.com/myrrlyn/wyz |
| y4m | 0.8.0 | MIT | https://github.com/image-rs/y4m.git |
| yuv | 0.1.10 | BSD-2-Clause | https://github.com/kornelski/yuv.git |
| zerocopy | 0.8.55 | BSD-2-Clause OR Apache-2.0 OR MIT | https://github.com/google/zerocopy |
| zerocopy-derive | 0.8.55 | BSD-2-Clause OR Apache-2.0 OR MIT | https://github.com/google/zerocopy |
| zlib-rs | 0.6.6 | Zlib | https://github.com/trifectatechfoundation/zlib-rs |
| zopfli | 0.8.3 | Apache-2.0 | https://github.com/zopfli-rs/zopfli |
| zune-core | 0.5.1 | MIT OR Apache-2.0 OR Zlib | https://github.com/etemesi254/zune-image |
| zune-jpeg | 0.5.15 | MIT OR Apache-2.0 OR Zlib | https://github.com/etemesi254/zune-image/tree/dev/crates/zune-jpeg |

This notice is informational and is not legal advice.
