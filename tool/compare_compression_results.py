#!/usr/bin/env python3
import argparse
import hashlib
import json
import math
import os
from pathlib import Path

import numpy as np
from PIL import Image


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def pixels(path: Path) -> np.ndarray:
    with Image.open(path) as image:
        return np.asarray(image.convert("RGB"), dtype=np.int16)


def metrics(candidate: np.ndarray, target: np.ndarray) -> dict[str, object]:
    if candidate.shape != target.shape:
        return {
            "same_dimensions": False,
            "pixel_equal": False,
            "mae": None,
            "psnr": None,
        }
    difference = candidate.astype(np.float32) - target.astype(np.float32)
    mse = float(np.mean(difference * difference))
    mae = float(np.mean(np.abs(difference)))
    return {
        "same_dimensions": True,
        "pixel_equal": bool(np.array_equal(candidate, target)),
        "mae": mae,
        "psnr": None if mse == 0 else 10 * math.log10(255 * 255 / mse),
    }


def format_metric(value: object, digits: int = 4) -> str:
    if value is None:
        return "—"
    if isinstance(value, float):
        return f"{value:.{digits}f}"
    return str(value)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--results", type=Path, required=True)
    parser.add_argument("--json-output", type=Path, required=True)
    parser.add_argument("--markdown-output", type=Path, required=True)
    args = parser.parse_args()

    original_pixels = pixels(args.input)
    reference_pixels = pixels(args.reference)
    reference_bytes = args.reference.read_bytes()
    outputs = sorted(
        path
        for path in args.results.rglob("*.jpeg")
        if path.resolve() not in {args.input.resolve(), args.reference.resolve()}
    )
    if not outputs:
        raise SystemExit("No platform JPEG outputs were found.")

    rows = []
    decoded_outputs = {}
    for output in outputs:
        output_pixels = pixels(output)
        decoded_outputs[output.stem] = output_pixels
        reference_metrics = metrics(output_pixels, reference_pixels)
        original_metrics = metrics(output_pixels, original_pixels)
        rows.append(
            {
                "platform": output.stem,
                "path": str(output),
                "bytes": output.stat().st_size,
                "sha256": sha256(output),
                "rgb_sha256": hashlib.sha256(
                    output_pixels.astype(np.uint8).tobytes()
                ).hexdigest(),
                "byte_equal_to_cli": output.read_bytes() == reference_bytes,
                "pixel_equal_to_cli": reference_metrics["pixel_equal"],
                "mae_vs_cli": reference_metrics["mae"],
                "psnr_vs_cli": reference_metrics["psnr"],
                "mae_vs_original": original_metrics["mae"],
                "psnr_vs_original": original_metrics["psnr"],
            }
        )

    pairs = []
    for index, left in enumerate(rows):
        for right in rows[index + 1 :]:
            left_pixels = decoded_outputs[left["platform"]]
            right_pixels = decoded_outputs[right["platform"]]
            pair_metrics = metrics(left_pixels, right_pixels)
            pairs.append(
                {
                    "left": left["platform"],
                    "right": right["platform"],
                    "byte_equal": left["sha256"] == right["sha256"],
                    "pixel_equal": pair_metrics["pixel_equal"],
                    "mae": pair_metrics["mae"],
                    "psnr": pair_metrics["psnr"],
                }
            )

    report = {
        "input": {
            "path": str(args.input),
            "bytes": args.input.stat().st_size,
            "sha256": sha256(args.input),
        },
        "cli_reference": {
            "path": str(args.reference),
            "bytes": args.reference.stat().st_size,
            "sha256": sha256(args.reference),
        },
        "platforms": rows,
        "platform_pairs": pairs,
    }
    args.json_output.write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Compression parity",
        "",
        f"CLI reference: `{args.reference.stat().st_size}` bytes, "
        f"`{sha256(args.reference)}`.",
        "",
        "| Platform | Bytes | SHA-256 | Byte equal | Pixel equal | "
        "RGB SHA-256 | MAE vs CLI | PSNR vs CLI | PSNR vs original |",
        "| --- | ---: | --- | --- | --- | --- | ---: | ---: | ---: |",
    ]
    for row in rows:
        lines.append(
            f"| {row['platform']} | {row['bytes']} | `{row['sha256']}` | "
            f"{row['byte_equal_to_cli']} | {row['pixel_equal_to_cli']} | "
            f"`{row['rgb_sha256']}` | "
            f"{format_metric(row['mae_vs_cli'])} | "
            f"{format_metric(row['psnr_vs_cli'])} dB | "
            f"{format_metric(row['psnr_vs_original'])} dB |"
        )
    lines.extend(
        [
            "",
            "## Cross-platform pairs",
            "",
            "| Pair | Byte equal | Pixel equal | MAE | PSNR |",
            "| --- | --- | --- | ---: | ---: |",
        ]
    )
    for pair in pairs:
        lines.append(
            f"| {pair['left']} ↔ {pair['right']} | {pair['byte_equal']} | "
            f"{pair['pixel_equal']} | {format_metric(pair['mae'])} | "
            f"{format_metric(pair['psnr'])} dB |"
        )
    lines.extend(
        [
            "",
            "Byte equality means identical JPEG files. Pixel equality compares "
            "decoded RGB samples; PSNR/MAE quantify non-identical lossy output.",
            "",
        ]
    )
    markdown = "\n".join(lines)
    args.markdown_output.write_text(markdown, encoding="utf-8")
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as summary:
            summary.write(markdown)


if __name__ == "__main__":
    main()
