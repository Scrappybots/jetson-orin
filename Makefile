RUNTIME := podman
BASE := registry.redhat.io/rhel9/rhel-bootc:9.4
REGISTRY := registry.jharmison.com
REPOSITORY := l4t/image
TAG := latest
IMAGE = $(REGISTRY)/$(REPOSITORY):$(TAG)
USER := james

.PHONY: all
all: .push boot-image/l4t-bootc.iso

.build: overlay/usr/local/bin/setup.sh Containerfile $(wildcard overlay/usr/local/lib/setup.sh.d/*.sh)
	$(RUNTIME) build --arch aarch64 --pull=always --from $(BASE) . -t $(IMAGE)
	@touch .build

.push: .build
	$(RUNTIME) push $(IMAGE)
	@touch .push

boot-image/bootc.ks: boot-image/bootc.ks.tpl
	IMAGE=$(IMAGE) USER=$(USER) envsubst '$$IMAGE,$$USER' < $< >$@

boot-image/l4t-bootc.iso: boot-image/bootc.ks boot-image/rhel-9.4-aarch64-boot.iso
	$(RUNTIME) run --arch aarch64 -v ./boot-image:/workdir --privileged --security-opt label=disable --entrypoint bash --workdir /workdir $(BASE) -exc \
		'dnf -y install lorax && mkksiso bootc.ks rhel-9.4-aarch64-boot.iso l4t-boot.iso'
