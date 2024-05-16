# Basic setup
text
network --bootproto=dhcp --device=link --activate

# Partition/volume setup
clearpart --all --initlabel --disklabel=gpt --drives=mmcblk0
reqpart --add-boot
part --grow --fstype xfs --ondisk=mmcblk0 /
logvol --noformat --fstype xfs --name var --vgname data /var

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
user --name ${USER} --lock --uid 1000 --gid 1000 --groups wheel,video,render
sshkey --username ${USER} "${SSH_KEY}"

%post --log=/root/anaconda-ks-post.log
set -x
mv /tmp/anaconda-ks-pre.log /root/

# Enable passwordless sudo for the configured user
echo '${USER} ALL=(ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/${USER}
%end

reboot
