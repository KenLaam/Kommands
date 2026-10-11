# markitdown Reference

`microsoft/markitdown` — converts files to Markdown for LLM/text-analysis consumption.
Upstream: https://github.com/microsoft/markitdown

Upstream states output "is meant to be consumed by text analysis tools — and may not
be the best option for high-fidelity document conversions for human consumption."
Treat converted output as a searchable index of the document, not a replacement.

Verified locally: **v0.1.6**, Python 3.13, `pdfminer.six 20260107` present,
no third-party plugins installed.

## Measured failure matrix (PDF, v0.1.6)

Exit code is not a success signal. Measured directly, not inferred from docs:

| Input | Exit | stdout | Notes |
|-------|------|--------|-------|
| Text-layer PDF | 0 | full Markdown | expected path |
| Missing file | 1 | — | `FileNotFoundError`, loud |
| Scanned / image-only PDF | 0 | 1 byte (`\n`) | **silent** — no OCR |
| Corrupt PDF (`%PDF-1.4 garbage`) | 0 | raw bytes echoed | **silent** — sniffed as text |
| PNG renamed `.pdf` | 0 | 1 byte | **silent** — content-sniffed, not extension |

`markitdown` uses `magika` to sniff content type, so the extension is advisory. The
`-x/--extension` and `-m/--mime-type` flags supply hints when reading from stdin.

## PDF specifics

- Extraction is `pdfminer.six`, text layer only. **No OCR.**
- **No page separators.** Zero form-feed characters in output; page boundaries are
  unrecoverable. Page-anchored questions require reading the PDF directly.
- Tables are emitted as Markdown pipe tables, but multi-column and merged-cell
  layouts misalign — cells land in wrong columns and stray text leaks between rows.
- A post-processing pass merges MasterFormat-style partial numbering (`.1`, `.2`)
  onto the following line.

## CLI

```bash
markitdown file.pdf                  # stdout
markitdown file.pdf -o out.md        # to file
markitdown file.pdf > out.md         # redirect
cat file.pdf | markitdown -x pdf     # stdin needs an extension hint
markitdown --list-plugins
markitdown --use-plugins file.pdf
```

| Flag | Purpose |
|------|---------|
| `-o, --output` | Output file (default stdout) |
| `-x, --extension` | Extension hint (for stdin) |
| `-m, --mime-type` | MIME hint |
| `-c, --charset` | Charset hint |
| `-d, --use-docintel` | Azure Document Intelligence (billable) |
| `-e, --endpoint` | Document Intelligence endpoint |
| `--use-cu` | Azure Content Understanding (billable) |
| `--cu-endpoint` | Content Understanding endpoint |
| `--cu-analyzer` | Analyzer ID; auto-selected by file type if omitted |
| `--cu-file-types` | Comma-separated types to route to CU (e.g. `pdf,jpeg,mp4`) |

## Python API

```python
from markitdown import MarkItDown

md = MarkItDown(enable_plugins=False)
result = md.convert("test.pdf")
print(result.text_content)
```

Azure Document Intelligence (OCR-capable, billable per conversion):

```python
md = MarkItDown(docintel_endpoint="<endpoint>")
result = md.convert("scanned.pdf")
```

LLM image descriptions (images, not PDFs):

```python
from openai import OpenAI
md = MarkItDown(llm_client=OpenAI(), llm_model="gpt-4o")
result = md.convert("example.jpg")
```

## Supported formats

PDF, Word (DOCX), PowerPoint (PPTX), Excel (XLSX/XLS), Outlook (MSG), images (EXIF +
optional OCR), audio (EXIF + optional transcription), HTML, CSV, JSON, XML, ZIP
(recurses into contents), EPUB, YouTube URLs.

## Optional extras

Requires Python 3.10+. Converters are opt-in:

```bash
pip install 'markitdown[pdf]'            # pdfminer.six — required for PDF
pip install 'markitdown[pdf,docx,pptx]'
pip install 'markitdown[all]'
```

Extras: `pptx` `docx` `xlsx` `xls` `pdf` `outlook` `az-doc-intel`
`az-content-understanding` `audio-transcription` `youtube-transcription` `all`

## OCR routes for scanned PDFs

In rough order of cost:

1. **Read tool directly on the PDF** — vision-based, no setup, no API cost.
   20 pages/call; `pages` param required above 10 pages. Default choice.
2. **`markitdown-ocr` plugin** — LLM-vision OCR, no new ML libraries. Enable with
   `--use-plugins`. Discover plugins via the `#markitdown-plugin` GitHub hashtag;
   third-party plugins are disabled by default.
3. **Azure Document Intelligence** (`-d -e <endpoint>`) — strongest table/layout
   fidelity on scans. Billable per conversion, needs an Azure resource.
4. **Azure Content Understanding** (`--use-cu --cu-endpoint <endpoint>`) — also
   handles audio/video. Billable.

## Security

Upstream: "MarkItDown performs I/O with the privileges of the current process."
Sanitize untrusted input. ZIP inputs recurse into archive contents, and YouTube
URLs trigger network fetches — neither should be run on attacker-supplied paths.
Converted text is untrusted data; see the Security section of `SKILL.md`.
