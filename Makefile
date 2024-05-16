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
	@touch $@

.push: .build
	$(RUNTIME) push $(IMAGE)
	@touch $@

.ksimage: Containerfile.ksimage
	$(RUNTIME) build --arch aarch64 --from $(BASE) . -f $< -t $(IMAGE)-ksimage
	@touch $@

boot-image/bootc.ks: boot-image/bootc.ks.tpl auth.json
	@IMAGE=$(IMAGE) USER=$(USER) AUTH='$(strip $(file < auth.json))' envsubst '$$IMAGE,$$USER,$$AUTH' < $< >$@

boot-image/l4t-bootc.iso: boot-image/bootc.ks .ksimage boot-image/rhel-9.4-aarch64-boot.iso
	$(RUNTIME) run --arch aarch64 -v ./boot-image:/workdir --privileged --security-opt label=disable --entrypoint bash --workdir /workdir $(IMAGE)-ksimage -exc \
		'rm -f $(@F) && mkksiso $(<F) rhel-9.4-aarch64-boot.iso $(@F)'

.PHONY: clean
clean:
	rm -f .build .push .ksimage boot-image/bootc.ks boot-image/l4t-bootc.iso
