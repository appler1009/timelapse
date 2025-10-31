#!/bin/bash

# --- Configuration ---

# Check if the correct number of arguments is provided
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <input_video_file> <start_second> <end_second> [output_video_file]"
    echo ""
    echo "This script trims a video from start_second to end_second, then creates a 3x speed timelapse"
    echo "with fades and 90% volume reduction."
    echo ""
    echo "Example: $0 movie.mp4 60 120"
    echo "         $0 movie.mp4 60 120 my_custom_output.mp4"
    exit 1
fi

INPUT_FILE="$1"
START_TIME="$2"
END_TIME="$3"
OUTPUT_VIDEO="${4:-}"

# Calculate duration (end time - start time)
DURATION=$((END_TIME - START_TIME))

# Derive output filename if not provided
INPUT_DIR=$(dirname "$INPUT_FILE")
BASE_NAME=$(basename "$INPUT_FILE")
EXTENSION="${BASE_NAME##*.}"
FILENAME_NO_EXT="${BASE_NAME%.*}"

if [[ -z "$OUTPUT_VIDEO" ]]; then
    OUTPUT_VIDEO="${INPUT_DIR}/${FILENAME_NO_EXT}_trimmed_${START_TIME}s_to_${END_TIME}s_timelapse.${EXTENSION}"
fi

# Temporary trimmed file (will be deleted after processing)
TEMP_TRIMMED="${INPUT_DIR}/${FILENAME_NO_EXT}_temp_trimmed_${START_TIME}_${END_TIME}.${EXTENSION}"

# --- Timelapse Parameters ---
SPEED_FACTOR="3"      # 3x faster
VOL_ORIGINAL="0.1"    # 0.1 for 90% volume reduction
FADE_DURATION="3.0"   # 3-second fade in/out

# --- Check for Dependencies and Input Files ---
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed or not in PATH."
    exit 1
fi

if ! command -v ffprobe &> /dev/null; then
    echo "Error: ffprobe is not installed or not in PATH."
    exit 1
fi

if ! command -v bc &> /dev/null; then
    echo "Error: bc is not installed or not in PATH."
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

echo "======================================================================"
echo "TRIM AND TIMELAPSE PROCESSING"
echo "======================================================================"
echo "Input: $INPUT_FILE"
echo "Trim Range: ${START_TIME}s to ${END_TIME}s (duration: ${DURATION}s)"
echo "Output: $OUTPUT_VIDEO"
echo "======================================================================"

# --- Step 1: Trim the Video ---
echo ""
echo "STEP 1: Trimming video..."
echo "----------------------------------------------------------------------"

ffmpeg -y \
-ss "$START_TIME" \
-i "$INPUT_FILE" \
-t "$DURATION" \
-c copy \
"$TEMP_TRIMMED"

if [ $? -ne 0 ]; then
    echo "Error: FFmpeg trimming failed."
    exit 1
fi

echo "Trimming complete. Temporary file: $TEMP_TRIMMED"

# --- Step 2: Get Trimmed Video Duration ---
echo ""
echo "STEP 2: Analyzing trimmed video properties..."
echo "----------------------------------------------------------------------"

TRIMMED_DURATION=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$TEMP_TRIMMED" | awk '{printf "%.3f", $1}')
if [[ -z "$TRIMMED_DURATION" ]]; then
    echo "Error: Could not retrieve trimmed video duration."
    rm -f "$TEMP_TRIMMED"
    exit 1
fi

echo "Trimmed Duration: $TRIMMED_DURATION seconds."

# Calculate PTS Multiplier (1/3 for 3x speed)
PTS_MULTIPLIER=$(echo "scale=6; 1 / $SPEED_FACTOR" | bc -l)

# Calculate final duration and fade-out start time
FINAL_DURATION=$(echo "$TRIMMED_DURATION * $PTS_MULTIPLIER" | bc -l)
FINAL_DURATION=$(printf "%.3f" "$FINAL_DURATION")
FADE_OUT_START=$(echo "$FINAL_DURATION - $FADE_DURATION" | bc -l)
FADE_OUT_START=$(printf "%.3f" "$FADE_OUT_START")

echo "Final Timelapse Duration (at ${SPEED_FACTOR}x): $FINAL_DURATION seconds."
echo "Fade Out Start Time: $FADE_OUT_START seconds (for a ${FADE_DURATION}s fade)."

# --- Step 3: Create Timelapse Video with Effects ---
echo ""
echo "STEP 3: Creating timelapse with 3x speed, fades, and audio adjustment..."
echo "----------------------------------------------------------------------"

ffmpeg -y -i "$TEMP_TRIMMED" \
-filter_complex \
"[0:v]setpts=${PTS_MULTIPLIER}*PTS,fade=t=in:st=0:d=${FADE_DURATION},fade=t=out:st=${FADE_OUT_START}:d=${FADE_DURATION}[v_out]; \
 [0:a]atrim=0:${FINAL_DURATION},asetpts=PTS/${SPEED_FACTOR},volume=${VOL_ORIGINAL},afade=t=in:st=0:d=${FADE_DURATION},afade=t=out:st=${FADE_OUT_START}:d=${FADE_DURATION}[a_out]" \
-map "[v_out]" \
-map "[a_out]" \
-c:v libx264 \
-crf 23 \
-preset veryfast \
"$OUTPUT_VIDEO"

if [ $? -ne 0 ]; then
    echo "Error: FFmpeg timelapse processing failed."
    rm -f "$TEMP_TRIMMED"
    exit 1
fi

# --- Step 4: Cleanup ---
echo ""
echo "STEP 4: Cleaning up temporary files..."
echo "----------------------------------------------------------------------"
rm -f "$TEMP_TRIMMED"
echo "Temporary file removed: $TEMP_TRIMMED"

echo ""
echo "======================================================================"
echo "SUCCESS! Final video generated as: $OUTPUT_VIDEO"
echo "======================================================================"
