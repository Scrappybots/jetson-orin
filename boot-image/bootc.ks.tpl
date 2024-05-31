# Basic setup
cmdline
network --bootproto=dhcp --device=link --activate

# Partition/volume setup
zerombr
clearpart --all --initlabel --disklabel=gpt
reqpart --add-boot
part / --fstype xfs --size 100 --grow --ondisk mmcblk0

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
cat << 'EOF' > /etc/ostree/auth.json
${AUTH}
EOF
%end

reboot
