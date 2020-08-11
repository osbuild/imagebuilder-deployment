#!/bin/bash
set -euxo pipefail

hostnamectl set-hostname ${worker_hostname}

echo ${composer_hostname} | tee /etc/osbuild-composer/composer_hostname

dnf -y install git python3-pip
pip3 install ansible

ansible-pull \
  -i localhost, \
  -U https://github.com/osbuild/imagebuilder-deployment \
  -m git playbooks/main.yml