RUNTIME := podman
BASE := registry.redhat.io/rhel9/rhel-bootc:9.4
DEST := /dev/sda

include Makefile.common

.PHONY: all
all: .push boot-image/l4t-bootc.iso rhel-ai

overlays/users/usr/local/ssh/core.keys:
	@echo Please put the authorized_keys file you would like for the core user in $@ >&2
	@exit 1

.build: Containerfile Containerfile.devel $(shell git ls-files | grep '^overlays/') overlays/users/usr/local/ssh/core.keys
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(BASE) . -t $(IMAGE)
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --from $(IMAGE) --pull=never -f Containerfile.devel . -t $(IMAGE)-devel
	@touch $@

.push: .build
	$(CMD_PREFIX) $(RUNTIME) push $(IMAGE)
	$(CMD_PREFIX) $(RUNTIME) push $(IMAGE)-devel
	@touch $@

.ksimage: Containerfile.ksimage
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --from $(BASE) . -f $< -t $(IMAGE)-ksimage
	@touch $@

boot-image/bootc.ks: boot-image/bootc.ks.tpl auth.json
	$(CMD_PREFIX) IMAGE=$(IMAGE) AUTH='$(strip $(file < auth.json))' envsubst '$$IMAGE,$$AUTH' < $< >$@
	@echo Updated kickstart

boot-image/l4t-bootc.iso: boot-image/bootc.ks .ksimage boot-image/rhel-9.4-aarch64-boot.iso
	$(CMD_PREFIX) $(RUNTIME) run --rm --arch aarch64 -v ./boot-image:/workdir --privileged --security-opt label=disable --entrypoint bash --workdir /workdir $(IMAGE)-ksimage -exc \
		'ksvalidator $(<F) && rm -f $(@F) && mkksiso $(<F) rhel-9.4-aarch64-boot.iso $(@F)'

.PHONY: debug
debug:
	$(CMD_PREFIX) $(RUNTIME) run --rm -it --arch aarch64 --entrypoint /bin/bash $(IMAGE)-devel -li

.PHONY: update
update:
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(IMAGE) -f Containerfile.update . -t $(IMAGE)
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(IMAGE)-devel -f Containerfile.update . -t $(IMAGE)-devel
	$(CMD_PREFIX) $(RUNTIME) push $(IMAGE)
	$(CMD_PREFIX) $(RUNTIME) push $(IMAGE)-devel

.PHONY: burn
burn: boot-image/l4t-bootc.iso
	$(CMD_PREFIX) sudo dd if=./boot-image/l4t-bootc.iso of=$(DEST) bs=1M conv=fsync status=progress

.PHONY: clean
clean:
	$(CMD_PREFIX) rm -f .build .push .ksimage boot-image/bootc.ks boot-image/l4t-bootc.iso images/rhel-ai/overlays/vllm/build/workspace
	$(CMD_PREFIX) buildah prune -f

.PHONY: rhel-ai
rhel-ai:
	$(MAKE) -C images/rhel-ai
