#!/bin/bash

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$0")/test-data/images"

# Change to the target directory
cd "$(dirname "$0")/test-data/images" || exit

# Base URL of the GitHub repository


# Get the list of files from the GitHub repository
file_list=$(curl -s https://api.github.com/repos/EliSchwartz/imagenet-sample-images/contents | grep 'download_url' | cut -d '"' -f 4)

# Download each file
for file_url in $file_list; do
    curl -O "$file_url"
done

echo "Download completed."