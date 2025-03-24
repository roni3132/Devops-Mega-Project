#!/bin/bash
set -e

# Path to the .env file
file_to_find="../frontend/.env.docker"

# Check if the .env file exists
if [ ! -f "$file_to_find" ]; then
    echo "ERROR: File $file_to_find not found."
    exit 1
fi

# Get EC2 instance IDs for all EKS nodes
INSTANCE_IDS=$(kubectl get nodes -o json | jq -r '.items[].spec.providerID' | sed 's|aws:///||' | cut -d'/' -f2)

# Loop through each instance ID and update the .env file
for INSTANCE_ID in $INSTANCE_IDS; do
    # Retrieve the public IP address of the EC2 instance
    ipv4_address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null)

    # Check if IP retrieval was successful
    if [ "$ipv4_address" == "None" ] || [ -z "$ipv4_address" ]; then
        echo "ERROR: Could not retrieve IP for instance $INSTANCE_ID. Skipping."
        continue
    fi

    # Check the current VITE_API_PATH in the .env file
    current_url=$(grep 'VITE_API_PATH' $file_to_find)

    # Update the .env file if necessary
    if [[ "$current_url" != "VITE_API_PATH=\"http://${ipv4_address}:31100\"" ]]; then
        sed -i -e "s|VITE_API_PATH.*|VITE_API_PATH=\"http://${ipv4_address}:31100\"|g" $file_to_find
        echo "Updated VITE_API_PATH to http://${ipv4_address}:31100 for instance $INSTANCE_ID."
    else
        echo "VITE_API_PATH is already up-to-date for instance $INSTANCE_ID."
    fi
done
