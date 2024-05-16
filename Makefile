RUNTIME := podman
BASE := registry.redhat.io/rhel9/rhel-bootc:9.4
REGISTRY := registry.jharmison.com
REPOSITORY := l4t/image
TAG := latest
IMAGE = $(REGISTRY)/$(REPOSITORY):$(TAG)
USER := james
SSH_KEY := ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCgGljB+CYmrCZ5ATJBdkCXOYNSdcXSSmq4TZsgzLNsvyaOI+arOOtZ0JAwYmg/wPHck0AaHP4rFhB4PohRbn9Z8n2lRlEtCQcKhgb1ZVSa2KFlWfk+/eCxdkx0QBZx2h0kQzOYhJx4fC35H1gsdK5fmRGZ4a1r+DjPpmJGcsuNptz/eoKhIa9jGaM7gFFKLgJYQ5cOeNJIXc1tMQCMXwPERIPSYRwPh8LcJ0B+f1hZml2FSNItxYUapykvWD7tPWHANSqVf00SIVjDQFrjoUZibj2JofDwdBepIktMoe0MDgV8n60CulCVGktfx7EObd4nq5eMhCziU3bwkjUsRYfTyCmSTUz82qFns7R0eG+48XftHziQGa+tgNehafrHLLLPgnt9lPeeIqkTxupRx+pl299AC9qKqw0WBSuWc7JQZy3rSQbh/w1dBll+t32mgn4NSND7ED/6knmWCXMnM9NeXH8SHmBJRELe/annM1ahCm0LRXVh3i/yLzPqPacjzIPW3JMpLEGnsBtFHNp7hCcfzhfH52ecqVzK1ZAkKZH4r3LOpX+i20Dq61AeATaiiqKokrLDmz16hkRhmiF6pvatBGVy8Lqnipht7RxnLTMl+is2hcBtYYvTY6BPAs2ImgnuSWdbHdBC6ag4IDZzv+XsHGBncQ/h8duv+IQ9W1b+zQ== jharmison@redhat.com
DEST := /dev/sda

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
	@IMAGE=$(IMAGE) USER=$(USER) AUTH='$(strip $(file < auth.json))' SSH_KEY='$(SSH_KEY)' envsubst '$$IMAGE,$$USER,$$AUTH,$$SSH_KEY' < $< >$@
	@echo Updated kickstart

boot-image/l4t-bootc.iso: boot-image/bootc.ks .ksimage boot-image/rhel-9.4-aarch64-boot.iso
	$(RUNTIME) run --arch aarch64 -v ./boot-image:/workdir --privileged --security-opt label=disable --entrypoint bash --workdir /workdir $(IMAGE)-ksimage -exc \
		'rm -f $(@F) && mkksiso $(<F) rhel-9.4-aarch64-boot.iso $(@F)'

.PHONY: burn
burn: boot-image/l4t-bootc.iso
	sudo dd if=./boot-image/l4t-bootc.iso of=$(DEST) bs=1M conv=fsync status=progress

.PHONY: clean
clean:
	rm -f .build .push .ksimage boot-image/bootc.ks boot-image/l4t-bootc.iso
