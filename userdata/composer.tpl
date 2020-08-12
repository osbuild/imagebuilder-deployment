#!/bin/bash
set -euxo pipefail

hostnamectl set-hostname ${composer_hostname}

subscription-manager register --auto-attach \
  --username="${rhn_registration_username}" \
  --password="${rhn_registration_password}"

subscription-manager repos --enable=ansible-2.9-for-rhel-8-x86_64-rpms

rm -rf /var/lob/rhsm/rhsm.log

dnf -y install ansible git python3-pip

ansible-pull \
  --inventory localhost, \
  --url https://github.com/osbuild/imagebuilder-deployment \
  --checkout main \
  --module-name git \
  playbooks/main.yml
