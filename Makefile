RUNTIME := podman
BASE := registry.redhat.io/rhel9/rhel-bootc:9.4
REGISTRY := registry.jharmison.com
REPOSITORY := l4t/image
TAG := latest
IMAGE = $(REGISTRY)/$(REPOSITORY):$(TAG)
DEST := /dev/sda

.PHONY: all
all: .push boot-image/l4t-bootc.iso

.build: Containerfile $(shell find overlays -type f)
	$(RUNTIME) build --arch aarch64 --build-arg --pull=always --from $(BASE) . -t $(IMAGE)
	@touch $@

.push: .build
	$(RUNTIME) push $(IMAGE)
	@touch $@

.ksimage: Containerfile.ksimage
	$(RUNTIME) build --arch aarch64 --from $(BASE) . -f $< -t $(IMAGE)-ksimage
	@touch $@

boot-image/bootc.ks: boot-image/bootc.ks.tpl auth.json
	@IMAGE=$(IMAGE) AUTH='$(strip $(file < auth.json))' envsubst '$$IMAGE,$$AUTH' < $< >$@
	@echo Updated kickstart

boot-image/l4t-bootc.iso: boot-image/bootc.ks .ksimage boot-image/rhel-9.4-aarch64-boot.iso
	$(RUNTIME) run --rm --arch aarch64 -v ./boot-image:/workdir --privileged --security-opt label=disable --entrypoint bash --workdir /workdir $(IMAGE)-ksimage -exc \
		'ksvalidator $(<F) && rm -f $(@F) && mkksiso $(<F) rhel-9.4-aarch64-boot.iso $(@F)'

.PHONY: debug
debug: .build
	$(RUNTIME) run --rm -it --arch aarch64 --entrypoint /bin/bash $(IMAGE) -li

.PHONY: update
update:
	$(RUNTIME) build --arch aarch64 --pull=always --from $(IMAGE) -f Containerfile.update . -t $(IMAGE)
	$(RUNTIME) push $(IMAGE)

.PHONY: burn
burn: boot-image/l4t-bootc.iso
	sudo dd if=./boot-image/l4t-bootc.iso of=$(DEST) bs=1M conv=fsync status=progress

.PHONY: clean
clean:
	rm -f .build .push .ksimage boot-image/bootc.ks boot-image/l4t-bootc.iso
