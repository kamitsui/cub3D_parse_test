#!/bin/bash

# Directories and files
MAP_DIR="map/error_kamitsui"
TRACE_DIR="trace"
PROGRAM="./cub3D"
SANITIZER_FLAGS="-fsanitize=address,undefined"
TRACE_FILE="test_results.log"

# Clear previous logs
> "$TRACE_FILE"

select_make_exection() {
	# Prompt the user for action
	echo "Do you want to compile? (with sanitize flag)? (y/n)"
	read -r user_input
	
	if [ "$user_input" == "y" ]; then
	    # Compile with sanitizers
	    echo "Compiling with sanitizer flags..."
	    make clean
	    CFLAGS="$SANITIZER_FLAGS" make
	
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
	local exit_status=0
	for file in "$MAP_DIR"/*.cub; do
	    echo "Testing with $file..." | tee -a "$TRACE_FILE"
	
	    # Run the program and capture outputs
	    valgrind --leak-check=full --error-exitcode=1 "$PROGRAM" "$file" >> "$TRACE_FILE" 2>&1
		exit_status=$?
	    echo "Exit Status = $exit_status" | tee -a "$TRACE_FILE"
	    if [ $exit_status -eq 0 ]; then
	        echo "Test Passed for $file" | tee -a "$TRACE_FILE"
	    else
	        echo "Test Failed for $file" | tee -a "$TRACE_FILE"
	    fi
	    echo "------------------------------------" >> "$TRACE_FILE"
	done
}

select_make_exection
leak_check
