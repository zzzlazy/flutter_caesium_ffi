# Compression parity fixture

`input.jpeg` is the 3840×1725 source image selected from Codex task
`019f92d9-6b8d-7682-97a3-576e61b9c19e`.

`cli-reference.jpeg` is the local command-line result supplied beside that
source image. Its JPEG quantization tables correspond to quality 62. The parity
workflow therefore uses these explicit settings on every platform:

- JPEG quality 62;
- automatic chroma subsampling;
- progressive output;
- optimization disabled;
- EXIF and ICC metadata removed;
- original dimensions retained.

SHA-256:

```text
35f5cbcf42337206c818cf8c17f2bbeb309add5b8d4579b3432acedc6304e6c7  input.jpeg
a912ddc04331f10752862a06fae2464231bef69327c1b7f042fc31421dba677b  cli-reference.jpeg
```
