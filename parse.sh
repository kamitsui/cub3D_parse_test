#!/bin/bash

# Define colors for OK and KO messages
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No color

# Create symbolic link to ../cub3D
ln -sf ../cub3D ./cub3D

# Directory containing test .cub files
ERROR_MAP_DIR="MAP/error"

# Check if the error map directory exists
if [ ! -d "$ERROR_MAP_DIR" ]; then
    echo "Error: Directory $ERROR_MAP_DIR does not exist."
    exit 1
fi

# Loop through all .cub files in the error map directory
for file in "$ERROR_MAP_DIR"/*.cub; do
    # Check if there are no .cub files
    if [ ! -e "$file" ]; then
        echo "No .cub files found in $ERROR_MAP_DIR."
        break
    fi

    ## Execute cub3D with the .cub file and capture output and exit status
    output=$(./cub3D "$file" 2>&1)
    exit_status=$?

    # Check if the program exited with EXIT_FAILURE (status 1) and printed an error message
    if [ $exit_status -eq 1 ] && [[ $output == *"Error"* ]]; then
        echo -e "${GREEN}OK${NC} - $file"
    else
        echo -e "${RED}KO${NC} - $file"
    fi
done
