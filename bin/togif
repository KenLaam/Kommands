#!/bin/zsh -f
# Convert screen recordings to looping GIFs (or small MP4s) written beside the source.

setopt no_unset pipe_fail

readonly PROG=${0:t}
readonly -a WIDTH_LADDER=(480 400 320)
readonly PALETTE_WIDTH=320
readonly NO_FRAMES=2

# Finder Quick Actions run with a bare system PATH.
path+=(/opt/homebrew/bin /usr/local/bin)

usage() {
  cat <<EOF
Usage: $PROG [options] <video>...

Writes <name>.gif beside each input. The source is never modified and an
existing file is never overwritten (a -2, -3... suffix is added instead).
The width steps down (native, ${(j:, :)WIDTH_LADDER}) until the GIF fits --max-mb.

  --from TIME    start offset, in seconds or [HH:]MM:SS
  --to TIME      end offset
  --fps N        frame rate (default: 10 for GIF, source rate for MP4)
  --width PX     fixed output width; turns off the automatic step-down
  --max-mb N     size budget in MB (default: 10)
  --mp4          write <name>-small.mp4 (H.264, no audio) instead of a GIF
  -h, --help     show this help
EOF
}

warn() {
  print -ru2 -- "$PROG: $*"
}

die() {
  warn "$@"
  exit 2
}

unique_path() {
  local stem=$1 ext=$2
  local candidate=$stem.$ext n=2
  while [[ -e $candidate ]]; do
    candidate=$stem-$n.$ext
    (( n++ ))
  done
  print -r -- $candidate
}

probe_width() {
  ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 -i $1
}

has_video() {
  [[ -n $(ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of csv=p=0 -i $1 2>/dev/null) ]]
}

has_frames() {
  local packets=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 -i $1 2>/dev/null)
  [[ $packets == <1-> ]]
}

megabytes() {
  printf '%.1f' $(( $1 / 1e6 ))
}

# Two passes keep memory flat: a single split/palettegen/paletteuse graph buffers
# every frame until the palette is ready (about 1 GB for a 30 s recording).
encode_gif() {
  local in=$1 work=$2
  local palette=$work/palette.png
  ffmpeg -v error -nostdin -y $trim -i $in \
    -vf "fps=$gif_fps,scale='min(iw,$PALETTE_WIDTH)':-1:flags=lanczos,palettegen=stats_mode=diff" \
    -frames:v 1 -update 1 -f image2 $palette || return 1
  # ffmpeg exits 0 without writing anything when the trim range holds no frames.
  [[ -s $palette ]] || return $NO_FRAMES

  local -a rungs
  if [[ -n $width ]]; then
    rungs=($width)
  else
    rungs=(native $WIDTH_LADDER)
  fi

  local rung scale_width
  native_width=0
  for rung in $rungs; do
    if [[ $rung == native ]]; then
      scale_width=iw
    else
      (( native_width && rung >= native_width )) && continue
      scale_width="'min(iw,$rung)'"
    fi
    ffmpeg -v error -nostdin -y $trim -i $in -i $palette \
      -lavfi "fps=$gif_fps,mpdecimate,scale=$scale_width:-1:flags=lanczos[v];[v][1:v]paletteuse=dither=none:diff_mode=rectangle" \
      -fps_mode vfr -loop 0 -f gif $work/out || return 1
    [[ $rung == native ]] && native_width=$(probe_width $work/out)
    (( $(stat -f %z $work/out) <= max_bytes )) && break
  done
  return 0
}

encode_mp4() {
  local in=$1 work=$2
  local -a filters
  [[ -n $fps ]] && filters+=("fps=$fps")
  if [[ -n $width ]]; then
    filters+=("scale='trunc(min(iw,$width)/2)*2':-2")
  else
    filters+=("scale=trunc(iw/2)*2:trunc(ih/2)*2")
  fi
  ffmpeg -v error -nostdin -y $trim -i $in -an -vf ${(j:,:)filters} \
    -c:v libx264 -crf 28 -pix_fmt yuv420p -movflags +faststart -f mp4 $work/out || return 1
  has_frames $work/out || return $NO_FRAMES
  native_width=0
  return 0
}

convert() {
  local in=$1 work=$2
  if [[ ! -f $in || ! -r $in ]]; then
    warn "${in:t}: no such file"
    return 1
  fi
  if ! has_video $in; then
    warn "${in:t}: no video stream found"
    return 1
  fi

  local out
  rm -f $work/palette.png $work/out
  if (( as_mp4 )); then
    out=$(unique_path ${in:r}-small mp4)
    encode_mp4 $in $work
  else
    out=$(unique_path ${in:r} gif)
    encode_gif $in $work
  fi
  case $? in
    0)
      ;;
    $NO_FRAMES)
      warn "${in:t}: no frames between --from and --to"
      return 1
      ;;
    *)
      warn "${in:t}: conversion failed"
      return 1
      ;;
  esac

  local bytes=$(stat -f %z $work/out)
  local out_width=$(probe_width $work/out)
  if ! mv -n $work/out $out || [[ -e $work/out ]]; then
    warn "${in:t}: could not write $out"
    return 1
  fi

  local note=""
  if (( native_width > out_width )); then
    note=" (stepped down from $native_width px to fit $max_mb MB)"
  fi
  print -r -- "${out:t}: $(megabytes $bytes) MB, $out_width px wide$note"
  if (( bytes > max_bytes )); then
    local hint="trim it with --from/--to, lower --fps, or use --mp4"
    (( as_mp4 )) && hint="trim it with --from/--to or set a smaller --width"
    warn "${out:t} is over the $max_mb MB budget; $hint"
  fi
  return 0
}

from="" to="" fps="" width="" max_mb=10 as_mp4=0
inputs=()
while (( $# )); do
  case $1 in
    --from|--to|--fps|--width|--max-mb)
      (( $# >= 2 )) || die "$1 needs a value"
      case $1 in
        --from) from=$2 ;;
        --to) to=$2 ;;
        --fps) fps=$2 ;;
        --width) width=$2 ;;
        --max-mb) max_mb=$2 ;;
      esac
      shift 2
      ;;
    --mp4)
      as_mp4=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      inputs+=("$@")
      break
      ;;
    -?*)
      die "unknown option $1 (see --help)"
      ;;
    *)
      inputs+=("$1")
      shift
      ;;
  esac
done

(( $#inputs )) || { usage >&2; exit 2 }
[[ -z $fps || ( $fps == <->(|.<->) && $fps -gt 0 ) ]] || die "--fps must be a positive number"
[[ -z $width || $width == <1-> ]] || die "--width must be a positive whole number of pixels"
[[ $max_mb == <->(|.<->) && $max_mb -gt 0 ]] || die "--max-mb must be a positive number"
(( $+commands[ffmpeg] && $+commands[ffprobe] )) || die "ffmpeg and ffprobe are required (brew install ffmpeg)"

trim=()
[[ -n $from ]] && trim+=(-ss $from)
[[ -n $to ]] && trim+=(-to $to)
gif_fps=${fps:-10}
(( max_bytes = max_mb * 1000000 ))
native_width=0

work=$(mktemp -d "${TMPDIR:-/tmp}/togif.XXXXXX") || die "could not create a temporary directory"
trap 'rm -rf $work' EXIT
trap 'exit 130' INT TERM

failed=0
for input in $inputs; do
  convert ${input:a} $work || failed=1
done
exit $failed
