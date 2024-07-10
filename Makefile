RUNTIME ?= podman
DISK ?= mmcblk0
ISO_DEST ?= /dev/sda
RHCOS_VERSION ?= 4.16
KVER ?= 5.14.0-427.18.1.el9_4.aarch64
IMAGE_SUFFIX ?=

include Makefile.common

.PHONY: all
all: .push boot-image/l4t-bootc-rhcos.iso rhel-ai

overlays/users/usr/local/ssh/core.keys:
	@echo Please put the authorized_keys file you would like for the core user in $@ >&2
	@exit 1

overlays/auth/etc/ostree/auth.json:
	@if [ -e "$@" ]; then touch "$@"; else echo "Please put the auth.json for your registry $(REGISTRY)/$(REPOSITORY) in $@"; exit 1; fi

.build: Containerfile Containerfile.devel overlays/auth/etc/ostree/auth.json $(shell git ls-files | grep '^overlays/') overlays/users/usr/local/ssh/core.keys
	$(RUNTIME) build --security-opt label=disable --arch aarch64 --build-arg KVER=$(KVER) --pull=newer --from $(BASE) . -t $(IMAGE)
	$(RUNTIME) build --security-opt label=disable --arch aarch64 --from $(IMAGE) --pull=never -f Containerfile.devel . -t $(IMAGE)-devel
	@touch $@

.PHONY: build
build: .build

.push: .build
	$(RUNTIME) push $(IMAGE)
	$(RUNTIME) push $(IMAGE)-devel
	@touch $@

.PHONY: push
push: .push

boot-image/rhcos-live.aarch64.iso:
	curl -Lo $@ https://mirror.openshift.com/pub/openshift-v4/aarch64/dependencies/rhcos/$(RHCOS_VERSION)/latest/rhcos-live.aarch64.iso

.base:
	$(RUNTIME) pull --arch aarch64 $(BASE)
	$(RUNTIME) push --remove-signatures $(BASE) $(REGISTRY)/$(REPOSITORY):base
	touch .base

boot-image/bootc$(IMAGE_SUFFIX).btn: boot-image/bootc.btn.tpl overlays/auth/etc/ostree/auth.json
	IMAGE=$(IMAGE)$(IMAGE_SUFFIX) AUTH='$(strip $(file < overlays/auth/etc/ostree/auth.json))' DISK=$(DISK) envsubst '$$IMAGE,$$AUTH,$$DISK' < $< >$@

boot-image/bootc$(IMAGE_SUFFIX).ign: boot-image/bootc$(IMAGE_SUFFIX).btn
	$(RUNTIME) run --rm -i quay.io/coreos/butane:release --pretty --strict < $< >$@

boot-image/l4t-bootc-rhcos$(IMAGE_SUFFIX).iso: boot-image/bootc$(IMAGE_SUFFIX).ign
	@if [ -e $@ ]; then rm -f $@; fi
	$(RUNTIME) run --rm --arch aarch64 --security-opt label=disable --pull=newer -v ./:/data -w /data \
    	quay.io/coreos/coreos-installer:release iso customize --live-ignition=./$< \
    	-o $@ boot-image/rhcos-live.aarch64.iso

.PHONY: burn
burn: boot-image/l4t-bootc-rhcos$(IMAGE_SUFFIX).iso
	sudo dd if=./$< of=$(ISO_DEST) bs=1M conv=fsync status=progress

.PHONY: debug
debug:
	$(RUNTIME) run --rm -it --arch aarch64 --pull=never --entrypoint /bin/bash $(IMAGE)-devel -li

.PHONY: update
update:
	$(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=newer --from $(IMAGE) -f Containerfile.update . -t $(IMAGE)
	$(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=newer --from $(IMAGE)-devel -f Containerfile.update . -t $(IMAGE)-devel
	$(RUNTIME) push $(IMAGE)
	$(RUNTIME) push $(IMAGE)-devel

.PHONY: clean
clean:
	rm -rf .build .push boot-image/*.iso boot-image/*.btn boot-image/*.ign images/rhel-ai/overlays/vllm/build/workspace
	buildah prune -f

.PHONY: rhel-ai
rhel-ai:
	$(MAKE) -C images/rhel-ai
