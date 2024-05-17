# Basic setup
cmdline
network --bootproto=dhcp --device=link --activate

# Partition/volume setup
zerombr
clearpart --all --initlabel --disklabel=gpt
reqpart --add-boot
part pv.01 --grow --ondisk mmcblk0
volgroup rhel pv.01
logvol --fstype xfs --grow --name root --vgname rhel /

part pv.02 --grow --ondisk nvme0n1
volgroup data pv.02
logvol --fstype xfs --grow --name var --vgname data /var

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

%post --log=/var/roothome/anaconda-ks-post.log
set -x
mv /tmp/anaconda-ks-pre.log /var/roothome/
%end

reboot
