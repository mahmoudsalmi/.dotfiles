#!/bin/sh

# get list of screenshots, usually in ~/Desktop/ and have a name like "Capture d’écran 2025-06-24 à 11.03.21.png"
screenshot_dir="$HOME/Desktop"
screenshot_files=$(find "$screenshot_dir" -maxdepth 1 -type f -name "Capture d’écran *.png" | sort -r)

# Check if there are any screenshot files
if [ -z "$screenshot_files" ]; then
  echo "No screenshots found."
  exit 1
fi

# Get the most recent screenshot file
latest_screenshot=$(echo "$screenshot_files" | head -n 1)

# Check if the latest screenshot file exists
if [ ! -f "$latest_screenshot" ]; then
  echo "Latest screenshot file does not exist."
  exit 1
fi

# New folder : second parameter, or current directory if not specified
new_folder="${2:-$(pwd)}"
# New name : first parameter, or maintaining the original name
new_name="${1:-$(basename "$latest_screenshot")}"

# preserve the original file extension
new_extension="${new_name##*.}"
if [ "$new_extension" != "png" ]; then
  new_name="${new_name%.*}.png"
fi

# Output the path of the latest screenshot
echo "Last screenshot : $latest_screenshot"
echo "Target location : $new_folder/$new_name"

mv -v "$latest_screenshot" "$new_folder/$new_name"
