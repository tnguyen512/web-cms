#!/bin/bash

# This script builds all extensions in the extensions directory

# Navigate to the extensions directory
cd extensions

# Check if extensions directory exists
if [ ! -d "." ]; then
    echo "Extensions directory not found!"
    exit 1
fi

# List all directories in extensions folder
for extension in */; do
    if [ -d "$extension" ]; then
        echo "Building extension: ${extension%/}"
        
        # Navigate into extension directory
        cd "$extension"
        
        # Check if package.json exists
        if [ -f "package.json" ]; then
            # Install dependencies if node_modules doesn't exist
            if [ ! -d "node_modules" ]; then
                echo "Installing dependencies for ${extension%/}..."
                npm install
            fi
            
            # Run build command
            echo "Running build for ${extension%/}..."
            npm run build
        else
            echo "No package.json found in ${extension%/}, skipping..."
        fi
        
        # Navigate back to extensions directory
        cd ..
    fi
done

echo "All extensions have been built successfully!"

