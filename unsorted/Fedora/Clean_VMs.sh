#!/bin/bash

qcow_files=(*.qcow2)
num_vms=${#qcow_files[@]}
echo "Found $num_vms VMs to clean."
echo

failed_vms=()

for (( i=0; i<$num_vms; i++ )); do
    qcow_file="${qcow_files[i]}"
    vm_name="${qcow_file%.qcow2}"
    echo "Cleaning $vm_name VM ($((i+1)) of $num_vms)"
    if [ "$(uname -s)" == "Linux" ] && [ -x "$(command -v apt-get)" ]; then
        sudo virt-sparsify --in-place "$qcow_file"
    else
        virt-sparsify --in-place "$qcow_file"
    fi
    if [ $? -ne 0 ]; then
        echo "Error: virt-sparsify failed for $vm_name"
        echo
        read -p "Press ENTER to continue or CTRL+C to exit"
        failed_vms+=("$vm_name")
    fi
    echo
done

if [ ${#failed_vms[@]} -eq 0 ]; then
    echo "All operations completed with no errors."
else
    echo "The following VMs failed to clean:"
    printf '%s\n' "${failed_vms[@]}"
fi

echo
#read -p "Press ENTER to exit."

qcow_files=(*.qcow2)
num_vms=${#qcow_files[@]}
echo "Found $num_vms VMs to shink."
echo

failed_vms=()

for (( i=0; i<$num_vms; i++ )); do
    qcow_file="${qcow_files[i]}"
    vm_name="${qcow_file%.qcow2}"
    
    # Skip FreeBSD and Puppy VMs
    if [[ "$vm_name" == *"FreeBSD"* ]]; then
        echo "Skipping $vm_name VM ($((i+1)) of $num_vms)"
        continue
    fi

    echo "Reclaiming space for $vm_name VM ($((i+1)) of $num_vms)"
    if [ "$(uname -s)" == "Linux" ] && [ -x "$(command -v apt-get)" ]; then
        sudo qemu-img convert -O qcow2 "$qcow_file" "${qcow_file%.qcow2}-reclaimed.qcow2"
    else
        qemu-img convert -O qcow2 "$qcow_file" "${qcow_file%.qcow2}-reclaimed.qcow2"
    fi
    if [ $? -ne 0 ]; then
        echo "Error: qemu-img convert failed for $vm_name"
        echo
        read -p "Press ENTER to continue or CTRL+C to exit"
        failed_vms+=("$vm_name")
    else
        mv "${qcow_file%.qcow2}-reclaimed.qcow2" "$qcow_file"
    fi
    echo
done

if [ ${#failed_vms[@]} -eq 0 ]; then
    echo "All operations completed with no errors."
else
    echo "The following VMs failed to reclaim space:"
    printf '%s\n' "${failed_vms[@]}"
fi

echo
read -p "Press ENTER to exit."
