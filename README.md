# Timelapse Video Creator

A bash script that trims video segments and creates smooth timelapse videos with 3x speed, fade effects, and audio adjustments.

## Features

- **Video Trimming**: Extract specific time segments from video files
- **3x Speed Timelapse**: Creates accelerated video playback
- **Smooth Transitions**: Automatic fade-in and fade-out effects (3 seconds each)
- **Audio Processing**: Maintains audio with 90% volume reduction and matching fades
- **Flexible Output**: Automatically generates descriptive filenames or use custom names

## Requirements

- `ffmpeg` - Video processing engine
- `ffprobe` - Video analysis tool  
- `bc` - Basic calculator for mathematical operations

## Usage

```bash
./tt.sh <input_video_file> <start_second> <end_second> [output_video_file]
```

### Parameters

- `input_video_file`: Path to your source video
- `start_second`: Start time in seconds for trimming
- `end_second`: End time in seconds for trimming  
- `output_video_file`: (Optional) Custom output filename

### Examples

```bash
# Basic usage - auto-generated filename
./tt.sh movie.mp4 60 120

# Custom output filename
./tt.sh movie.mp4 60 120 my_awesome_timelapse.mp4
```

## How It Works

1. **Trim**: Extracts the specified time segment from the input video
2. **Analyze**: Determines video properties and calculates timing for effects
3. **Process**: Creates timelapse with:
   - 3x playback speed
   - 3-second fade-in at start
   - 3-second fade-out at end
   - Audio volume reduced to 10% of original
   - H.264 encoding with CRF 23 quality
4. **Cleanup**: Removes temporary files

## Output

The script generates a new video file with the naming pattern:
`{original_name}_trimmed_{start}s_to_{end}s_timelapse.{extension}`

For example: `movie_trimmed_60s_to_120s_timelapse.mp4`

## Technical Details

- **Speed Factor**: 3x (configurable in script)
- **Volume Reduction**: 90% (10% remaining)
- **Fade Duration**: 3 seconds in/out
- **Video Codec**: H.264 with CRF 23
- **Encoding Preset**: veryfast for quick processing

## Installation

1. Clone this repository
2. Make the script executable: `chmod +x tt.sh`
3. Ensure dependencies are installed (ffmpeg, ffprobe, bc)
4. Run the script with your video files

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

Copyright 2024 Timelapse Video Creator

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.