#!/bin/bash -ex

for stub in /usr/local/lib/setup.sh.d/*.sh; do
	source "$stub"
done
