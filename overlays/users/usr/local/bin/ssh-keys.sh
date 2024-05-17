#!/bin/bash

for authorized_keys in /usr/local/lib/ssh-keys/*; do
	user=$(basename "$authorized_keys")
	uid=$(id -u "$user")
	gid=$(id -g "$user")
	home="/var/home/$user"
	mkdir -p "/var/home/$user/.ssh"
	cp "$authorized_keys" "$home/.ssh/authorized_keys"
	chmod u=rwX,g=,o= "$home"
	chmod -R u=rwX,g=,o= "$home/.ssh"
	chown -R "$uid:$gid" "$home"
	chcon -R -u unconfined_u -r object_r -t ssh_home_t "$home/.ssh"
done
