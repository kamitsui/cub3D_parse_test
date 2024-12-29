#!/bin/bash

# Define colors for OK and KO messages
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No color

# Define directories and trace files
DIR1="map/error_kusano"
DIR2="map/error_kamite"
DIR_TRACE="trace"
TRACE1="$DIR_TRACE/kusano.log"
TRACE2="$DIR_TRACE/kamite.log"

if [ ! -d "$DIR_TRACE" ]; then
	mkdir $DIR_TRACE
fi

# Create symbolic link to ../cub3D
ln -sf ../cub3D ./cub3D

# Function to test a directory
test_directory() {

	# Arguments assigned to local valiable
	local dir=$1
	local trace_file=$2

	# Initialize trace files with a header
	echo "Trace Log for $dir - $(date)" > "$trace_file"

	# Check if the directory exists
	if [ ! -d "$dir" ]; then
	    echo "Error: Directory $dir does not exist."
	    return 1
	fi

	# Loop through all .cub files in the directory
	for file in "$dir"/*.cub; do
	    # Check if there are no .cub files
	    if [ ! -e "$file" ]; then
	        echo "No .cub files found in $dir."
	        break
	    fi

	    ## Execute cub3D with the .cub file and capture output and exit status
	    output=$(./cub3D "$file" 2>&1)
	    exit_status=$?

	    # Check if the program exited with EXIT_FAILURE (status 1) and printed an error message
	    if [ $exit_status -eq 1 ] && [[ $output == *"Error"* ]]; then
	        echo -e "${GREEN}OK${NC} - $file"
			# Log OK result to the trace file
	        echo "=== OK Result for $file ===" >> "$trace_file"
	    else
	        echo -e "${RED}KO${NC} - $file"
			# Log KO result to the trace file
	        echo "=== KO Result for $file ===" >> "$trace_file"
	    fi

		# Append detailed execution information to the trace file
	        echo "Command: ./cub3D \"$file\"" >> "$trace_file"
	        echo "Exit Status: $exit_status" >> "$trace_file"
	        echo "Output:" >> "$trace_file"
	        echo "$output" >> "$trace_file"
	        echo "" >> "$trace_file"  # Add a blank line for readability
	done
}

# Test both directories
test_directory "$DIR1" "$TRACE1"
test_directory "$DIR2" "$TRACE2"
