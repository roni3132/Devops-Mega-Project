#!/bin/bash

# Path to the .env file
file_to_find="../backend/.env.docker"

# Check if the .env file exists
if [ ! -f "$file_to_find" ]; then
    echo "ERROR: File $file_to_find not found."
    exit 1
fi

# Get EC2 instance IDs for all EKS nodes
INSTANCE_IDS=$(kubectl get nodes -o json | jq -r '.items[].spec.providerID' | sed 's|aws:///||' | cut -d'/' -f2)

# Loop through each instance ID and update the .env file
for INSTANCE_ID in $INSTANCE_IDS; do
    # Get the public IP address of the instance
    ipv4_address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    
    # Check if IP retrieval was successful
    if [ "$ipv4_address" == "None" ] || [ -z "$ipv4_address" ]; then
        echo "ERROR: Could not retrieve IP for instance $INSTANCE_ID."
        continue
    fi

    # Update FRONTEND_URL in the .env file if necessary
    current_url=$(sed -n "4p" $file_to_find)

    # Update the .env file if necessary
    if [[ "$current_url" != "FRONTEND_URL=\"http://${ipv4_address}:5173\"" ]]; then
        sed -i -e "s|FRONTEND_URL.*|FRONTEND_URL=\"http://${ipv4_address}:5173\"|g" $file_to_find
        echo "Updated FRONTEND_URL to http://${ipv4_address}:5173 for instance $INSTANCE_ID."
    else
        echo "FRONTEND_URL is already up-to-date for instance $INSTANCE_ID."
    fi
done
