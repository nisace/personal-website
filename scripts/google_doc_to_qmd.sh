#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# Convert Google Doc → QMD with equations + drawings
# - DOCX handles equations and normal images
# - Published HTML provides Google Drawings (base64 PNGs)
# - Placeholders [[DRAWING]] in DOCX are replaced with drawings
# ==========================================

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 input.docx published.html output [PLACEHOLDER] [ALT_TEXT]"
    exit 1
fi

DOCX="$1"
HTML="$2"
OUT_QMD_DIR="$3"
PLACEHOLDER="${4:-\[\[DRAWING\]\]}"
ALT_TEXT="${5:-drawing}"

TMP_QMD="$OUT_QMD_DIR/tmp_docx_body.qmd"
TMP_IMAGES="$OUT_QMD_DIR/tmp_images.txt"
MEDIA_DIR_NAME="media"
MEDIA_DIR="$OUT_QMD_DIR/$MEDIA_DIR_NAME"
OUT_QMD="$OUT_QMD_DIR/output.qmd"

mkdir -p "$MEDIA_DIR"
rm -f "$TMP_IMAGES"

# ------------------------------------------
# Step 1: Convert DOCX → QMD (Pandoc)
# Required options:
#   -f docx
#   -t markdown+yaml_metadata_block+footnotes+definition_lists
#   --wrap=preserve
#   --extract-media
# ------------------------------------------
echo "→ Converting DOCX to QMD..."
pandoc "$DOCX" \
  -s \
  -f docx \
  -t markdown+yaml_metadata_block+footnotes+definition_lists \
  --wrap=preserve \
  --extract-media="$MEDIA_DIR" \
  -o "$TMP_QMD"

# ------------------------------------------
# Step 2: Extract Google Drawings from HTML
# - Only images with alt="$ALT_TEXT"
# - Save as media/drawing_N.png
# ------------------------------------------
echo "→ Extracting drawings from HTML..."
perl -0777 -ne '
    $i=1;
    while(/<img[^>]+alt="'$ALT_TEXT'"[^>]+src="data:image\/png;base64,([^"]+)"/g){
        $outfilename = "'$ALT_TEXT'_".$i.".png";
        $outfile = "'$MEDIA_DIR'/$outfilename";
        open(F, "|base64 --decode >$outfile") or die $!;
        print F $1;
        close(F);
        open(L, ">>'$TMP_IMAGES'") or die $!;
        print L "'$MEDIA_DIR_NAME'/$outfilename\n";
        close(L);
        $i++;
    }
' "$HTML"

# ------------------------------------------
# Step 3: Replace placeholders with images sequentially (macOS-safe Perl)
# ------------------------------------------
echo "→ Replacing placeholders in QMD..."
if [ -s "$TMP_IMAGES" ]; then
  while IFS= read -r img; do
    PH="$PLACEHOLDER" ALT="$ALT_TEXT" FILE="$img" \
    perl -0777 -i -pe '
      BEGIN {
        my $ph   = $ENV{PH};
        my $alt  = $ENV{ALT};
        my $file = $ENV{FILE};
        # Build the exact markdown we want to insert
        our $REP = "![]($file)";
        our $PH  = $ph;
      }
      # Replace only the FIRST occurrence in the entire file (no /g)
      s/\Q$PH\E/$REP/;
    ' "$TMP_QMD"
  done < "$TMP_IMAGES"
else
  echo "⚠️  No drawings found with alt text '$ALT_TEXT' in HTML."
fi

# ------------------------------------------
# Step 4: Finalize
# ------------------------------------------
mv "$TMP_QMD" "$OUT_QMD"
rm -f "$TMP_IMAGES"

echo "✅ Done! Output written to $OUT_QMD"
