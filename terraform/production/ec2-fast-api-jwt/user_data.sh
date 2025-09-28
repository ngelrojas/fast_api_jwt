#!/usr/bin/env sh
echo "Starting user data script..."

# Update package lists and install necessary packages
apt-get update -y
apt-get install -y python3 python3-pip git
echo "Installed Python, pip, and git."
