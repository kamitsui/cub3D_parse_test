#!/bin/bash

# Create symbolic link to ../cub3D
ln -sf ../cub3D ./cub3D

# Check if cub3D executable is available
if [ ! -f "cub3D" ]; then
    echo "Error: 'cub3D' executable not found in the current directory."
    exit 1
fi

# Set the target directory
TARGET_DIR="map"

# Check if the map directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

# Function to list items and navigate directories
select_file_or_directory() {
    local dir="$1"

    while true; do
        # List directories and .cub files
        echo "Contents of $dir:"
        local items=()
        local count=0
        for item in "$dir"/*; do
            if [ -d "$item" ] || [[ "$item" == *.cub ]]; then
                items+=("$item")
                echo "[$count] $(basename "$item")"
                count=$((count + 1))
            fi
        done

        # If no items are found
        if [ ${#items[@]} -eq 0 ]; then
            echo "No subdirectories or .cub files found in $dir."
            return 1
        fi

        # Prompt user to select an item
        echo -n "Enter the number of your choice (or 'q' to quit): "
        read -r choice

        if [[ "$choice" == "q" ]]; then
            echo "Exiting."
            return 1
        fi

        # Validate input
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -ge "${#items[@]}" ]; then
            echo "Invalid choice. Please try again."
            continue
        fi

        local selected="${items[$choice]}"

        # If the selection is a directory, navigate into it
        if [ -d "$selected" ]; then
            select_file_or_directory "$selected"
            return $? # Propagate the result of the recursive call
        elif [[ "$selected" == *.cub ]]; then
            echo "Selected file: $selected"
            echo
            echo "Running: ./cub3D \"$selected\""
            valgrind --leak-check=full ./cub3D "$selected"
            return 0
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Start the selection process from the target directory
select_file_or_directory "$TARGET_DIR"
