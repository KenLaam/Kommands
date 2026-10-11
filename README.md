# Kommands

Command-line tools and agent skills I use for macOS and iOS development.

| Tool | What it does |
|---|---|
| [`togif`](#togif) | Converts screen recordings to looping GIFs, or small MP4s, without leaving your Mac |

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
git clone https://github.com/KenLaam/Kommands.git
cd Kommands
mkdir -p ~/.local/bin
ln -s "$PWD/bin/togif" ~/.local/bin/togif
```

Make sure `~/.local/bin` is on your `PATH`.

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

To convert from Finder's right-click menu, install the script as above, then:

```sh
cp -R "quick-actions/Convert to GIF.workflow" ~/Library/Services/
/System/Library/CoreServices/pbs -update
```

Select one or more videos, right-click, and choose Quick Actions > Convert to
GIF. If the item is missing, enable it under Quick Actions > Customize…. The
Quick Action calls `~/.local/bin/togif`, so the script must be installed at
that path.

## Licence

[MIT](LICENSE)
