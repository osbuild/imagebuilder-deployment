#!/bin/bash
set -euxo pipefail

hostname-ctl set-hostname ${manager_hostname}

dnf -y install git python3-pip
pip3 install ansible

ansible-pull \
  -U https://github.com/osbuild/imagebuilder-deployment \
  -m git playbooks/main.yml