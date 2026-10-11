#!/usr/bin/env python3
"""Convert a PDF to Markdown via microsoft/markitdown, with validation guards.

markitdown exits 0 on several silent-failure modes (image-only PDFs yield an
empty document; corrupt files are echoed back as plain text). This wrapper
classifies the result so the caller knows whether the markdown is usable or
whether it must fall back to a vision-capable reader.

Exit codes:
    0  OK             - usable markdown written
    2  DEGENERATE     - PDF has no extractable text layer (scanned/image-only)
    3  BAD_INPUT      - missing file, or not a PDF
    4  TOOL_FAILURE   - markitdown missing or errored
"""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
import sys
from pathlib import Path

EXIT_OK = 0
EXIT_DEGENERATE = 2
EXIT_BAD_INPUT = 3
EXIT_TOOL_FAILURE = 4

PDF_MAGIC = b"%PDF"
DEFAULT_MIN_CHARS = 200
DEFAULT_MIN_CHARS_PER_PAGE = 50
CONVERSION_TIMEOUT_S = 300
CACHE_DIR = Path.home() / ".claude" / "cache" / "markitdown"

# /Type /Page not followed by 's' (avoids matching /Type /Pages). Only matches
# pages in uncompressed object streams; returns 0 for PDFs using compressed
# cross-reference streams, in which case per-page density checks are skipped.
PAGE_OBJ_RE = re.compile(rb"/Type\s*/Page(?![s\w])")


class ConversionError(RuntimeError):
    """markitdown could not be invoked or exited non-zero."""


def count_pages(raw: bytes) -> int:
    """Best-effort page count from raw PDF bytes. 0 means 'unknown'."""
    return len(PAGE_OBJ_RE.findall(raw))


def cache_path_for(pdf: Path) -> Path:
    """Stable output path keyed by identity + mtime + size, so edits invalidate."""
    stat = pdf.stat()
    fingerprint = f"{pdf.resolve()}|{stat.st_mtime_ns}|{stat.st_size}"
    digest = hashlib.sha256(fingerprint.encode()).hexdigest()[:10]
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", pdf.stem).strip("-") or "document"
    return CACHE_DIR / f"{slug}-{digest}.md"


def run_markitdown(pdf: Path, use_plugins: bool) -> str:
    exe = shutil.which("markitdown")
    if exe is None:
        raise ConversionError(
            "markitdown not found on PATH. Install: pip install 'markitdown[pdf]'"
        )

    cmd = [exe, str(pdf)]
    if use_plugins:
        cmd.append("--use-plugins")

    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            timeout=CONVERSION_TIMEOUT_S,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise ConversionError(
            f"markitdown timed out after {CONVERSION_TIMEOUT_S}s on {pdf.name}"
        ) from exc

    if proc.returncode != 0:
        detail = proc.stderr.decode("utf-8", "replace").strip().splitlines()
        tail = detail[-1] if detail else f"exit {proc.returncode}"
        raise ConversionError(f"markitdown failed on {pdf.name}: {tail}")

    return proc.stdout.decode("utf-8", "replace")


def classify(text: str, pages: int, min_chars: int) -> tuple[bool, str]:
    """Return (usable, reason). Guards markitdown's exit-0 failure modes."""
    body = text.strip()

    if body.startswith("%PDF"):
        return False, "markitdown echoed raw PDF bytes as text; file is corrupt"

    if len(body) < min_chars:
        return False, (
            f"only {len(body)} chars extracted (threshold {min_chars}); "
            "PDF has no text layer - likely scanned or image-only"
        )

    if pages > 0:
        density = len(body) / pages
        if density < DEFAULT_MIN_CHARS_PER_PAGE:
            return False, (
                f"{len(body)} chars across {pages} pages "
                f"({density:.0f}/page); most pages carry no text layer"
            )

    return True, "text layer extracted"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert a PDF to Markdown via markitdown, with validation."
    )
    parser.add_argument("pdf", type=Path, help="path to the source PDF")
    parser.add_argument(
        "-o", "--output", type=Path, help="output .md path (default: cache dir)"
    )
    parser.add_argument(
        "--force", action="store_true", help="reconvert even if cached output exists"
    )
    parser.add_argument(
        "--use-plugins",
        action="store_true",
        help="enable markitdown 3rd-party plugins (e.g. OCR)",
    )
    parser.add_argument(
        "--min-chars",
        type=int,
        default=DEFAULT_MIN_CHARS,
        help=f"degenerate-output threshold (default {DEFAULT_MIN_CHARS})",
    )
    args = parser.parse_args()

    pdf: Path = args.pdf
    if not pdf.is_file():
        print(f"ERROR: no such file: {pdf}", file=sys.stderr)
        return EXIT_BAD_INPUT

    with pdf.open("rb") as handle:
        header = handle.read(1024)
    if not header.startswith(PDF_MAGIC):
        print(
            f"ERROR: {pdf.name} is not a PDF (missing %PDF header). "
            "Read it directly instead of converting.",
            file=sys.stderr,
        )
        return EXIT_BAD_INPUT

    out = args.output or cache_path_for(pdf)
    out.parent.mkdir(parents=True, exist_ok=True)

    if out.exists() and not args.force:
        text = out.read_text(encoding="utf-8")
        print(f"CACHED   {out}")
        print(f"chars={len(text)} lines={text.count(chr(10)) + 1}")
        print(f"\nNEXT: Read {out}")
        return EXIT_OK

    try:
        text = run_markitdown(pdf, use_plugins=args.use_plugins)
    except ConversionError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return EXIT_TOOL_FAILURE

    pages = count_pages(pdf.read_bytes())
    usable, reason = classify(text, pages, args.min_chars)

    if not usable:
        print(f"DEGENERATE  {pdf.name}", file=sys.stderr)
        print(f"reason: {reason}", file=sys.stderr)
        print(
            "\nNEXT: do NOT trust this output. Read the PDF directly with the "
            "Read tool (vision-based, handles scans), or re-run with "
            "--use-plugins if an OCR plugin is installed.",
            file=sys.stderr,
        )
        return EXIT_DEGENERATE

    out.write_text(text, encoding="utf-8")
    page_note = f"pages={pages} " if pages else ""
    print(f"OK       {out}")
    print(f"{page_note}chars={len(text)} lines={text.count(chr(10)) + 1}")
    print(f"\nNEXT: Read {out}")
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
