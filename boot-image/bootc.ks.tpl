text
network --bootproto=dhcp --device=link --activate

clearpart --all --initlabel --disklabel=gpt --drives=mmcblk0
reqpart --add-boot
part --grow --fstype xfs --ondisk=mmcblk0 /
logvol --noformat --fstype xfs --name var --vgname data /var

%pre-install --erroronfail --log=/tmp/anaconda-ks-pre.log
set -x
cat << 'EOF' > /etc/ostree/auth.json
${AUTH}
EOF
%end

# Reference the container image to install - The kickstart
# has no %packages section. A container image is being installed.
ostreecontainer --transport registry --url ${IMAGE}

firewall --use-system-defaults
rootpw --iscrypted --lock
user --name ${USER} --lock --uid 1000 --gid 1000 --groups video,render

%post --log=/root/anaconda-ks-post.log
set -x
mv /tmp/anaconda-ks-pre.log /root/
%end

reboot
