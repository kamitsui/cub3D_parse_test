#!/bin/bash

# Define colors for OK and KO messages
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No color

# Directories and files
DIR_MAP1="map/error_kamitsui"
DIR_MAP2="map/error_kamite"
DIR_MAP3="map/error_kusano"
DIR_TRACE="trace"
PROGRAM="./cub3D"
SANITIZER_FLAGS="-fsanitize=address,undefined"
TRACE_FILE="$DIR_TRACE/kamitsui.log"
DIR_PROJECT=".."

# Create trace directory
if [ ! -d "$DIR_TRACE" ]; then
	mkdir $DIR_TRACE
fi

# Create symbolic link to ../cub3D
ln -sf $DIR_PROJECT/cub3D ./cub3D

# Clear previous logs
> "$TRACE_FILE"

select_make_exection() {
	# Prompt the user for action
	echo "Do you want to compile? (with sanitize flag)? (y/n)"
	read -r user_input
	
	if [ "$user_input" == "y" ]; then
	    # Compile with sanitizers
	    echo "Compiling with sanitizer flags..."
		make check -C $DIR_PROJECT
	
	    if [ $? -ne 0 ]; then
	        echo "Compilation failed. Exiting."
	        exit 1
	    fi
	else
	    echo "Skipping compilation and proceeding with valgrind checks..."
	fi
}

# Loop through all .cub files
leak_check() {
	local dir_map=$1
	echo "Checking files in directory: $dir_map" | tee -a "$TRACE_FILE"
	local exit_status=0

	for file in "$dir_map"/*.cub; do
		if [ ! -f "$file" ]; then
            echo "No .cub files found in $dir_map" | tee -a "$TRACE_FILE"
            continue
        fi

		export DISPLAY=":0.0 $PROGRAM $file"
	    echo "Testing with $file..." | tee -a "$TRACE_FILE"
	
	    # Run the program and capture outputs
	    valgrind --leak-check=full --error-exitcode=1 "$PROGRAM" "$file" >> "$TRACE_FILE" 2>&1
		exit_status=$?
	    echo "Exit Status = $exit_status" | tee -a "$TRACE_FILE"
	    if [ $exit_status -eq 0 ]; then
	        echo -e "Test ${GREEN}Passed${NC} for $file" | tee -a "$TRACE_FILE"
	    else
	        echo -e "Test ${RED}Failed${NC} for $file" | tee -a "$TRACE_FILE"
	    fi
	    echo "------------------------------------" >> "$TRACE_FILE"
	done
}

select_make_exection
leak_check "$DIR_MAP1"
leak_check "$DIR_MAP2"
leak_check "$DIR_MAP3"
