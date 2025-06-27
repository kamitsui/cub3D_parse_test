#!/bin/bash

# Define colors for OK and KO messages
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No color

# Directories and files
TARGET_DIR="map"
DIR_MAP1="map/error_kamitsui"
DIR_MAP2="map/error_kamite"
DIR_MAP3="map/error_kusano"
DIR_MAP4="map/OK_kamite"
DIR_MAP5="map/OK_kusano"
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

run_valgrind_and_trace() {
	local file=$1

	# Run the program and capture outputs
	valgrind --leak-check=full --error-exitcode=2 "$PROGRAM" "$file" >> "$TRACE_FILE" 2>&1
	local exit_status=$?
	if [ $exit_status -ne 2 ]; then
		echo -en "${GREEN}OK${NC} - $file\t" | tee -a "$TRACE_FILE"
	else
		echo -en "${RED}KO${NC} - $file\t" | tee -a "$TRACE_FILE"
	fi
	echo "Exit($exit_status)" | tee -a "$TRACE_FILE"
	return $exit_status
}

# Loop through all .cub files
leak_check_in_dir() {
	local dir_map=$1
	local exit_status
	echo "Checking files in directory: $dir_map" | tee -a "$TRACE_FILE"
	echo "--------- $dir_map -----------------" | tee -a "$TRACE_FILE"

	for file in "$dir_map"/*.cub; do
		if [ ! -f "$file" ]; then
		echo "No .cub files found in $dir_map" | tee -a "$TRACE_FILE"
		continue
	fi
		echo "Testing with $file..." >> $TRACE_FILE

		run_valgrind_and_trace $file
		exit_status=$?
		# Run the program and capture outputs
#		valgrind --leak-check=full --error-exitcode=2 "$PROGRAM" "$file" >> "$TRACE_FILE" 2>&1
#		exit_status=$?
#		if [ $exit_status -ne 2 ]; then
#			echo -en "${GREEN}OK${NC} - $file\t" | tee -a "$TRACE_FILE"
#		else
#			echo -en "${RED}KO${NC} - $file\t" | tee -a "$TRACE_FILE"
#		fi
#		echo "Exit($exit_status)" | tee -a "$TRACE_FILE"
		echo "------------------------------------" >> "$TRACE_FILE"
	done
	return $exit_status
}

select_directory() {
	local dir="$1"

	while true; do
		# List directories
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
		echo -n "Enter the number of your choice (or 'a' to all, or 'q' to quit): "
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
			leak_check_in_dir "$selected"
		    return $? # Propagate the result of the recursive call
		elif [[ "$selected" == *.cub ]]; then

		    echo "Testing with $selected..." >> $
			run_valgrind_and_trace $selected
		    return $?
		else
		    echo "Invalid selection. Please try again."
		fi
	done
}

select_make_exection
select_directory $TARGET_DIR
