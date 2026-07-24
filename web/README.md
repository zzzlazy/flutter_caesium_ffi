# Bundled libcaesium-wasm assets

`libcaesium_wasm/index.js` and `libcaesium_wasm/libcaesium_wasm.wasm` come
from the GitHub Pages build of
[`zzzlazy/libcaesium-wasm`](https://github.com/zzzlazy/libcaesium-wasm)
0.5.0 at commit `b1089e36ceea970fa15a85e8994dd786dceb9c0f`. That fork is
based on
[`Lymphatus/libcaesium-wasm`](https://github.com/Lymphatus/libcaesium-wasm).

The fork adds the browser integration needed by this package:

- accept an explicit WASM URL so Flutter package assets work under custom base
  paths;
- copy compressed bytes before releasing the Rust vector;
- release the input and option allocations after every operation;
- clamp GIF quality to the documented 1–100 range;
- expose target-size behavior and JPEG/PNG/WebP conversion.

Run `shasum -a 256 -c WEB_CHECKSUMS.sha256` after replacing or modifying either
runtime asset.
