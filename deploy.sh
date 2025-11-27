#!/bin/bash

# Deployment script for Salesforce components

echo "Starting deployment of Salesforce components..."

# Check if sf CLI is installed
if ! command -v sf &> /dev/null
then
    echo "Error: Salesforce CLI (sf) is not installed or not in PATH"
    exit 1
fi

# Deploy the components to the default org
echo "Deploying components to org..."
sf project deploy start

echo "Deployment completed."
