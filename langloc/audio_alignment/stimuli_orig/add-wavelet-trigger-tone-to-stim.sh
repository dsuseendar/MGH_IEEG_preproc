#!/bin/bash

# Define the path to the folder containing the .wav files
folder_path="./stimuli_orig"

# Define the path to the predefined audio file to concatenate
predefined_file="./stimuli_orig/wavelet-trigger-tone.wav"

# Define the path to the output folder
output_folder="./stimuli"

# Create the output folder if it doesn't exist
mkdir -p "$output_folder"

# Loop over all .wav files starting with numbers in the folder
for file in "$folder_path"/[0-9]*.wav; do
    echo "Processing file: $file"
    
    # Get the filename without the path
    file_name=$(basename "$file")
    
    # Concatenate the predefined file with the current file using the "sox" command
    output_file="$output_folder/${file_name%.wav}.wav"
    sox "$predefined_file" "$file" "$output_file"
    
    echo "Concatenation complete. Output file: $output_file"
done