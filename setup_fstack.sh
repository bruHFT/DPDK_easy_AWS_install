#!/bin/bash

# Set noninteractive mode to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Install python3-pip and automatically select default option for restart prompt
echo -e "\n" | sudo -E apt-get -y install python3-pip
