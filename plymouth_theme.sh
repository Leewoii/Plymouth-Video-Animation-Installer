#!/usr/bin/env bash
set -e

##############################
# Plymouth Theme Installer
# Author: Leewoii
##############################

### Install Packages

apt install -y ffmpeg

### Defaults
FRAME_DELAY_DEFAULT=5
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIDEO_DIR="$SCRIPT_DIR/video"
PLYMOUTH_BASE="/usr/share/plymouth/themes"

### Root check
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root."
  exit 1
fi

### Parse arguments (Way 2)
while getopts ":t:d:" opt; do
  case $opt in
    t) THEME_NAME="$OPTARG" ;;
    d) FRAME_DELAY="$OPTARG" ;;
    *)
      echo "Usage: $0 [-t ThemeName] [-d FrameDelay]"
      exit 1
      ;;
  esac
done

### Way 1 (interactive)
if [[ -z "$THEME_NAME" ]]; then
  read -rp "Name of your Plymouth theme: " THEME_NAME
fi

FRAME_DELAY="${FRAME_DELAY:-$FRAME_DELAY_DEFAULT}"

### Validate theme name
if [[ -z "$THEME_NAME" ]]; then
  echo "Theme name cannot be empty."
  exit 1
fi

### Check video directory
if [[ ! -d "$VIDEO_DIR" ]]; then
  echo "No 'video/' directory found."
  echo "Please create a 'video' folder next to this script,"
  echo "place a single .mp4 file inside it, and run the script again."
  exit 1
fi

VIDEO_FILE="$(find "$VIDEO_DIR" -maxdepth 1 -iname '*.mp4' | head -n 1)"

if [[ -z "$VIDEO_FILE" ]]; then
  echo "No .mp4 file found in the 'video/' directory."
  echo "Please place a video file there and re-run this script."
  exit 1
fi

### Create theme directories
THEME_DIR="$PLYMOUTH_BASE/$THEME_NAME"
FRAMES_DIR="$THEME_DIR/frames"

mkdir -p "$FRAMES_DIR"

echo "Extracting frames from video..."

### Extract frames (1280x720, numbered)
ffmpeg -y -i "$VIDEO_FILE" \
  -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2" \
  "$FRAMES_DIR/frame-%d.png"

FRAME_COUNT="$(ls "$FRAMES_DIR"/progress-*.png | wc -l)"

if [[ "$FRAME_COUNT" -eq 0 ]]; then
  echo "Frame extraction failed."
  exit 1
fi

echo "Extracted $FRAME_COUNT frames."

### Create boot.script
cat > "$THEME_DIR/boot.script" <<EOF
# --- Background ------------------------------------------------
Window.SetBackgroundTopColor(0.0, 0.0, 0.0);
Window.SetBackgroundBottomColor(0.0, 0.0, 0.0);

# --- Configuration --------------------------------------------
FRAME_COUNT = $FRAME_COUNT;
FRAME_DELAY = $FRAME_DELAY;
MAX_SCALE   = 1.0;

# --- Screen ----------------------------------------------------
screen_width  = Window.GetWidth();
screen_height = Window.GetHeight();

# --- Load frames ----------------------------------------------
Frame_Image = [];

for (i = 1; i <= FRAME_COUNT; i++)
{
  Frame_Image[i] = Image("frame-" + i + ".png");
}

# --- Scaling ---------------------------------------------------
base_image = Frame_Image[1];

scale_x = screen_width  / base_image.GetWidth();
scale_y = screen_height / base_image.GetHeight();
scale   = Math.min(scale_x, scale_y, MAX_SCALE);

for (i = 1; i <= FRAME_COUNT; i++)
{
  Frame_Image[i].Scale(scale, scale);
}

# --- Sprite ----------------------------------------------------
Frame_sprite = Sprite();
Frame_sprite.SetImage(Frame_Image[1]);

Frame_sprite.SetX((screen_width - Frame_Image[1].GetWidth()) / 2);
Frame_sprite.SetY((screen_height - Frame_Image[1].GetHeight()) / 2);

# --- Animation -------------------------------------------------
tick = 0;

fun refresh_callback ()
{
  frame = Math.Int(tick / FRAME_DELAY) % FRAME_COUNT;
  Frame_sprite.SetImage(Frame_Image[frame + 1]);
  tick++;
}

Plymouth.SetRefreshFunction(refresh_callback);
EOF

chmod 644 "$THEME_DIR/boot.script"

### Create .plymouth file
cat > "$THEME_DIR/$THEME_NAME.plymouth" <<EOF
[Plymouth Theme]
Name=$THEME_NAME
Description=Automated Plymouth animation created by Leewoii
ModuleName=script

[script]
ImageDir=$FRAMES_DIR
ScriptFile=$THEME_DIR/boot.script
EOF

### Register theme
update-alternatives --install \
  /usr/share/plymouth/themes/default.plymouth \
  default.plymouth \
  "$THEME_DIR/$THEME_NAME.plymouth" \
  100

update-alternatives --set default.plymouth \
  "$THEME_DIR/$THEME_NAME.plymouth"

### Rebuild initramfs
update-initramfs -u

### Countdown + reboot
echo "Plymouth theme '$THEME_NAME' created successfully."
echo "System will reboot in 5 seconds..."

for i in {5..1}; do
  echo "$i..."
  sleep 1
done

reboot
