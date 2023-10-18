#!/bin/bash

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 [directory1] [directory2] [directory3] ..."
  exit 1
fi

# Loop through the provided directory paths
for dir in "$@"; do
  # Check if the path is a directory
  if [ -d "$dir" ]; then
    echo "Contents of directory: $dir"
    ls -A "$dir"
    echo
  else
    echo "Not a valid directory: $dir"
  fi
done
