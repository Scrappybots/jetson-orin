# Basic setup
cmdline
network --bootproto=dhcp --device=link --activate

# Partition/volume setup
clearpart --all --initlabel --disklabel=gpt --drives=mmcblk0
reqpart --add-boot
part --grow --fstype xfs --ondisk=mmcblk0 /

clearpart --all --initlabel --disklabel=gpt --drives=nvme0n1
part pv.01 --size=100 --grow --ondisk=nvme0n1
volgroup data pv.01
logvol --fstype xfs --size=100 --grow --name var --vgname data /var

%pre-install --erroronfail --log=/tmp/anaconda-ks-pre.log
set -x

# Configure authentication for bootc image registry
cat << 'EOF' > /etc/ostree/auth.json
${AUTH}
EOF
%end

# bootc image installation
ostreecontainer --transport registry --url ${IMAGE}

# Firewall configuration
firewall --use-system-defaults

# User configuration
rootpw --iscrypted --lock

%post --log=/root/anaconda-ks-post.log
set -x
mv /tmp/anaconda-ks-pre.log /root/
%end

reboot
