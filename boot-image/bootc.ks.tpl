# Basic setup
cmdline
network --bootproto=dhcp --device=link --activate

# Partition/volume setup
zerombr
clearpart --all --initlabel --disklabel=gpt
reqpart --add-boot
part pv.01 --grow --ondisk mmcblk0
volgroup rhel pv.01
logvol --fstype xfs --size 100 --grow --name root --vgname rhel /

part pv.02 --grow --ondisk nvme0n1
volgroup data pv.02
logvol --fstype xfs --size 100 --grow --name var --vgname data /var

# bootc image installation
ostreecontainer --transport registry --url ${IMAGE}

# Firewall configuration
firewall --use-system-defaults

# User configuration
rootpw --lock

%pre-install --erroronfail --log=/tmp/anaconda-ks-pre.log
set -x

# Configure authentication for bootc image registry
cat << 'EOF' > /etc/ostree/auth.json
${AUTH}
EOF
%end

%post --log=/mnt/sysimage/var/roothome/anaconda-ks-post-no-chroot.log --nochroot
set -ex
mv /tmp/anaconda-ks-pre.log /mnt/sysimage/var/roothome/
%end

%post --log=/var/roothome/anaconda-ks-post.log
set -ex
groupadd -g 1000 core
useradd -c 'core' -d /var/home/core -u 1000 -g 1000 -m -G wheel -s /bin/bash core
mkdir -p /var/home/core/.ssh
cat << 'EOF' > /var/home/core/.ssh/authorized_keys
${SSH_KEYS}
EOF
echo 'core	ALL=(ALL)	NOPASSWD: ALL' > /etc/sudoers.d/core
chmod -R u=rwX,g=,o= /var/home/core/.ssh
chown -R 1000:1000 /var/home/core
%end

reboot
