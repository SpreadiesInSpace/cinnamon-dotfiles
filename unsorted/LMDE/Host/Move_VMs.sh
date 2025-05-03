#!/bin/bash

# Directory where the .qcow2 files are stored
vault_dir="${PWD}/Vault"

# Check if there are any .qcow2 files in the current directory
if ls *.qcow2 1> /dev/null 2>&1; then
    # If there are .qcow2 files, move them to the vault
    echo "Moving .qcow2 files to the vault..."
    mv *.qcow2 "$vault_dir"
else
    # If there are no .qcow2 files, check if there are any in the vault
    if ls "$vault_dir"/*.qcow2 1> /dev/null 2>&1; then
        # If there are .qcow2 files in the vault, move them to the current directory
        echo "Moving .qcow2 files from the vault..."
        mv "$vault_dir"/*.qcow2 "${PWD}"
    else
        # If there are no .qcow2 files in either location, print a message
        echo "No .qcow2 files found in either the current directory or the vault."
    fi
fi

