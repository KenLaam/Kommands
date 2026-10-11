# Kommands

Command-line tools and agent skills I use for macOS and iOS development.

| Item | Kind | What it does |
|---|---|---|
| [`togif`](#togif) | Tool | Converts screen recordings to looping GIFs or small MP4s, without leaving your Mac |
| [`fastlane-changelog`](#fastlane-changelog) | Skill | Writes TestFlight "What to Test" notes from git commits |
| [`pdf2md`](#pdf2md) | Skill | Converts PDFs to Markdown before an agent reads them |
| [`md2html`](#md2html) | Command | Converts a Markdown file to a styled standalone HTML page |

The tool is a plain shell script. The skills and the command are for
[Claude Code](https://claude.com/claude-code).

## Install

Clone the repo once:

```sh
git clone https://github.com/KenLaam/Kommands.git
cd Kommands
```

Then run either installer, or both. They are independent.

```sh
./tools/togif/install.sh      # the togif command and its Finder Quick Action
./install.sh                  # every skill and command, into ~/.claude
```

To install a single skill or command, name it. To remove what an installer
created, pass `--uninstall`:

```sh
./install.sh pdf2md                 # only pdf2md
./install.sh pdf2md md2html         # several items
./install.sh --uninstall            # remove every link
./install.sh --uninstall pdf2md     # remove one
./tools/togif/install.sh --uninstall
```

Both installers create symlinks into the clone, so:

- **Keep the clone where it is.** If you move it, run the installers again
  from the new location with `--force`.
- **`git pull` updates everything.** The one exception is the Finder Quick
  Action, which is a copy: re-run `./tools/togif/install.sh` after a pull that
  changes it.

Neither installer overwrites a file it did not create. If something is already
at a target path, the installer reports it and leaves it alone; `--force` moves the
existing file to a backup first (`~/.claude/backups/kommands-<timestamp>/` for
skills and commands, `~/.local/bin/togif.backup-<timestamp>` for `togif`).
Running an installer twice is safe.

`./install.sh` uses `$CLAUDE_CONFIG_DIR` when it is set and `~/.claude`
otherwise. Start a new Claude Code session after installing.

## togif

Turns a screen recording into a GIF written beside the source file. It exists
so that bug-reproduction videos never have to be uploaded to an online
converter.

```sh
togif recording.mp4                 # recording.gif, sized to fit under 10 MB
togif --from 3 --to 12 clip.mov     # only seconds 3 to 12
togif --mp4 clip.mov                # clip-small.mp4 instead of a GIF
togif --width 400 --fps 12 a.mp4 b.mp4
```

Each run prints one line per file with the size and the width it used:

```
recording.gif: 9.6 MB, 480 px wide (stepped down from 592 px to fit 10 MB)
```

### Requirements

- macOS with zsh (the system default)
- [ffmpeg](https://ffmpeg.org) and ffprobe: `brew install ffmpeg`

### Install

```sh
./tools/togif/install.sh
```

This links `togif` into `~/.local/bin` and copies the Finder Quick Action into
`~/Library/Services`. Make sure `~/.local/bin` is on your `PATH`; the installer
tells you when it is not.

| Option | Meaning |
|---|---|
| `--no-quick-action` | Link the command only |
| `--force` | Replace a `~/.local/bin/togif` the installer did not create, keeping the old one as `togif.backup-<timestamp>` |
| `--uninstall` | Remove the command link and the Quick Action |

### Options

| Option | Meaning |
|---|---|
| `--from TIME` | Start offset, in seconds or `[HH:]MM:SS` |
| `--to TIME` | End offset |
| `--fps N` | Frame rate. Default: 10 for GIF, the source rate for MP4 |
| `--width PX` | Fixed output width. Turns off the automatic step-down |
| `--max-mb N` | Size budget in MB. Default: 10 |
| `--mp4` | Write `<name>-small.mp4` (H.264, no audio) instead of a GIF |

### Behaviour

- **Size budget.** Without `--width`, the GIF is encoded at the source width
  first, then at 480, 400 and 320 px until it fits `--max-mb`. If even 320 px
  is too large, the file is still written and a warning suggests trimming or
  `--mp4`. The default of 10 MB matches GitHub's limit for an attached GIF.
- **Nothing is overwritten.** The source is never modified. If the output name
  is taken, a `-2`, `-3`… suffix is added.
- **GIF or MP4.** GIF is a heavy format: a 30 s phone recording at 592×1280
  came out at 9.6 MB as a 480 px GIF and 1.3 MB as a full-width MP4. Use
  `--mp4` wherever video plays inline.
- **Exit status.** 0 when every file converted, 1 when any file failed, 2 for
  a usage error.

### Finder Quick Action

The installer adds a Quick Action to Finder's right-click menu. Select one or
more videos, right-click, and choose Quick Actions > Convert to GIF. If the
item is missing, enable it under Quick Actions > Customize….

The Quick Action calls `~/.local/bin/togif`, which is a link into your clone.
macOS guards Desktop, Documents and Downloads, so a clone inside one of them
can trigger privacy prompts when the Quick Action runs. Clone somewhere else,
such as `~/Developer`.

## fastlane-changelog

A skill that writes `fastlane/changelog`, the file fastlane sends to TestFlight
as the "What to Test" notes. It collects the commits since the last build,
drops what testers do not care about (merges, build and version bumps, docs,
tests, dependency chores), and rewrites the rest as plain sentences, features
first. It does not run the deploy, bump the build number or upload anything.

### Requirements

The skill expects an iOS project that:

- uses git with conventional commits (`feat`, `fix`, `refactor` and so on)
- has a `fastlane/` directory at the repo root
- reads TestFlight release notes from `fastlane/changelog`
- marks each deploy with a "Bump build to N" commit

When no "Bump build to N" commit exists yet, the last 30 commits are used.

### Use

```sh
./install.sh fastlane-changelog
```

In Claude Code, ask for it before a deploy, for example "update the changelog
for the deploy" or "write the what to test notes for this build". The skill
shows the final list and leaves the deploy to you.

The notes are written in English by default. To use another language, say so
in the project's instructions (`CLAUDE.md`), for example:

```md
Write TestFlight release notes in French.
```

## pdf2md

A skill that converts a PDF to Markdown with
[markitdown](https://github.com/microsoft/markitdown) before the agent reads
it. Markdown costs far fewer tokens than reading the PDF as images, has no
page limit and can be searched. A wrapper script checks the result, because
`markitdown` reports success even when it extracted nothing.

### Requirements

- Python 3.9 or later
- markitdown with its PDF extra, on your `PATH` (markitdown itself needs
  Python 3.10 or later):

```sh
pip install 'markitdown[pdf]'
```

### Use

```sh
./install.sh pdf2md
```

The skill triggers by itself whenever a PDF is about to be read. Good to know:

- **Cache.** Converted files are kept in `~/.claude/cache/markitdown/` and
  reused until the PDF changes. The cache can hold whatever your PDFs hold, so
  clear it if that matters to you.
- **Scanned PDFs.** A PDF with no text layer cannot be converted. The skill
  detects this and reads the PDF directly instead.
- **Limits.** Converted text has no page numbers, complex tables can lose
  their structure, and images and charts are dropped.

## md2html

A slash command that turns a Markdown file into a single self-contained HTML
page: automatic dark and light theme, callouts, code blocks with copy buttons,
and a table of contents that follows the scroll position.

```sh
./install.sh md2html
```

Then, in Claude Code:

```
/md2html <input.md> [output.html]
```

Without an output path, the page is written beside the source with `.md`
replaced by `.html`. The agent does the conversion, not a script, so the
output can vary slightly between runs.

## Licence

[MIT](LICENSE)
