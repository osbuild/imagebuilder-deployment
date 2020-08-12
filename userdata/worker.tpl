#!/bin/bash
set -euxo pipefail

hostnamectl set-hostname ${worker_hostname}

subscription-manager register --auto-attach \
  --username="${rhn_registration_username}" \
  --password="${rhn_registration_password}"

subscription-manager repos --enable=ansible-2.9-for-rhel-8-x86_64-rpms

mkdir -p /etc/osbuild-composer
echo ${composer_hostname} | tee /etc/osbuild-composer/composer_hostname

dnf -y install ansible git python3-pip

ansible-pull \
  --inventory localhost, \
  --url https://github.com/osbuild/imagebuilder-deployment \
  --checkout main \
  --module-name git \
  playbooks/main.yml
