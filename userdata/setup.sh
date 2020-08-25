function is_composer {
  if [[ $NODE_TYPE == composer ]]; then
    return 0
  fi
  return 1
}

# Variables for the script.
EBS_STORAGE=/dev/nvme1n1
STATE_DIR=/var/lib/osbuild-composer

# Set the hostname to the hostname passed by terraform.
hostnamectl set-hostname $SYSTEM_HOSTNAME

# If we're on a worker, we need to add the instance ID to the hostname for
# easier identification.
if ! is_composer; then
  INSTANCE_ID=$(curl --retry 5 --location --silent http://169.254.169.254/latest/meta-data/instance-id)
  WORKER_HOSTNAME=$(echo $SYSTEM_HOSTNAME | sed "s/^worker/worker-${INSTANCE_ID}/")
  hostnamectl set-hostname $WORKER_HOSTNAME
fi

# Create a user.
useradd redhat
passwd -l redhat

# Set up ssh keys.
mkdir /home/redhat/.ssh
curl --retry 5 --location --silent \
  --output /home/redhat/.ssh/authorized_keys \
  https://github.com/osbuild/osbuild-composer/blob/master/schutzbot/team_ssh_keys.txt
chown -R redhat:redhat /home/redhat/.ssh
chmod 0700 /home/redhat/.ssh
chmod 0600 /home/redhat/.ssh/authorized_keys

# Install EPEL but disable the repository.
echo "fastestmirror=1" | tee -a /etc/dnf/dnf.conf
echo "install_weak_deps=0" | tee -a /etc/dnf/dnf.conf
curl --retry 5 --location --silent \
  --output /tmp/epel.rpm \
  https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
rpm -Uvh /tmp/epel.rpm
sed 's/^enabled.*/enabled=0/' /etc/yum.repos.d/epel.repo

# Deploy the osbuild repository.
tee /etc/yum.repos.d/osbuild.repo << EOF
[osbuild-mock]
name=osbuild
baseurl=http://osbuild-composer-repos.s3-website.us-east-2.amazonaws.com/osbuild/osbuild-composer/master/latest/rhel82_x86_64
enabled=1
gpgcheck=0
priority=5
EOF

# Install packages.
dnf -y install chrony composer-cli dnf-plugins-core \
  osbuild osbuild-composer python3-pip tmux vim

# Ensure chrony is running.
systemctl enable --now chronyd

# Install certbot packages on composer.
dnf -y --enablerepo=epel install \
  certbot python3-certbot python3-certbot-dns-route53

# Get certificates from LetsEncrypt.
certbot certonly --dns-route53 -m major@redhat.com --agree-tos --staging \
  --non-interactive -d $(hostname)

# Create symbolic links to the certs for osbuild-composer to use.
CERTS_DIR=/etc/letsencrypt/live/$(hostname)
COMPOSER_DIR=/etc/osbuild-composer/
mkdir -p $COMPOSER_DIR
if is_composer; then
  cp -afv ${CERTS_DIR}/cert.pem ${COMPOSER_DIR}/composer-crt.pem
  cp -afv ${CERTS_DIR}/privkey.pem ${COMPOSER_DIR}/composer-key.pem
else
  cp -afv ${CERTS_DIR}/cert.pem ${COMPOSER_DIR}/worker-crt.pem
  cp -afv ${CERTS_DIR}/privkey.pem ${COMPOSER_DIR}/worker-key.pem
fi
cp -afv ${CERTS_DIR}/fullchain.pem ${COMPOSER_DIR}/ca-crt.pem
chown -R _osbuild-composer:_osbuild-composer $COMPOSER_DIR

# Set up storage on composer.
if is_composer && ! grep ${STATE_DIR} /proc/mounts; then
  # Ensure EBS is fully connected first.
  for TIMER in {0..300}; do
    if stat $EBS_STORAGE; then
      break
    fi
    sleep 1
  done

  # Check if XFS filesystem is already made.
  if ! xfs_info $EBS_STORAGE; then
    mkfs.xfs $EBS_STORAGE
  fi

  # Make osbuild-composer state directory if missing.
  mkdir -p ${STATE_DIR}

  # Add to /etc/fstab and mount.
  echo "${EBS_STORAGE} ${STATE_DIR} xfs defaults 0 0" | tee -a /etc/fstab
  mount $EBS_STORAGE

  # Reset SELinux contexts.
  restorecon -Rv /var/lib

  # Set filesystem permissions.
  chown -R _osbuild-composer:_osbuild-composer ${STATE_DIR}

  # Verify that the storage is writable
  touch ${STATE_DIR}/.provisioning_check
  rm -f ${STATE_DIR}/.provisioning_check
fi

# Register to RHN.
subscription-manager register --auto-attach \
  --username="${RHN_USERNAME}" \
  --password="${RHN_PASSWORD}"

# Prepare all osbuild-composer services.
if is_composer; then
  # We want remote workers only, so prevent the local worker from starting.
  systemctl mask osbuild-worker@1.service
  systemctl enable --now osbuild-remote-worker.socket
else
  systemctl enable --now osbuild-remote-worker@${COMPOSER_HOSTNAME}:8700.service
fi

# Apply lorax patch to work around pytoml issues in RHEL 8.x.
# See BZ 1843704 or https://github.com/weldr/lorax/pull/1030 for more details.
sudo sed -r -i 's#toml.load\(args\[3\]\)#toml.load(open(args[3]))#' \
    /usr/lib/python3.6/site-packages/composer/cli/compose.py
sudo rm -f /usr/lib/python3.6/site-packages/composer/cli/compose.pyc

# Ensure all packages are updated.
dnf -y upgrade