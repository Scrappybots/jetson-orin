# Basic setup
text
network --bootproto=dhcp --device=link --activate
# Basic partitioning
clearpart --all --initlabel --disklabel=gpt --drives=mmcblk0
reqpart --add-boot
part --grow --fstype xfs --ondisk=mmcblk0 /
logvol --noformat --fstype xfs --name var --vgname data /var

# Reference the container image to install - The kickstart
# has no %packages section. A container image is being installed.
ostreecontainer --url ${IMAGE}

firewall --use-system-defaults

rootpw --iscrypted --lock
user --name ${USER} --lock --uid 1000 --gid 1000 --groups video,render
reboot
