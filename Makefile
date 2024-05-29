RUNTIME := podman
BASE := registry.redhat.io/rhel9/rhel-bootc:9.4
CUDA_BASE := nvcr.io/nvidia/cuda:12.3.2-devel-ubi9
CUDNN_BASE := nvcr.io/nvidia/cuda:12.1.1-cudnn8-devel-ubi9
REGISTRY := registry.jharmison.com
REPOSITORY := l4t/image
TAG := latest
IMAGE = $(REGISTRY)/$(REPOSITORY):$(TAG)
DEST := /dev/sda

#
# If you want to see the full commands, run:
#   NOISY_BUILD=y make
#
ifeq ($(NOISY_BUILD),)
    ECHO_PREFIX=@
    CMD_PREFIX=@
    PIPE_DEV_NULL=> /dev/null 2> /dev/null
else
    ECHO_PREFIX=@\#
    CMD_PREFIX=
    PIPE_DEV_NULL=
endif

.PHONY: all
all: .push boot-image/l4t-bootc.iso images/rhel-ai/.push

overlays/users/usr/local/ssh/core.keys:
	@echo Please put the authorized_keys file you would like for the core user in $@ >&2
	@exit 1

.build: Containerfile Containerfile.devel $(shell git ls-files | grep '^overlays/') overlays/users/usr/local/ssh/core.keys
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(BASE) . -t $(IMAGE)
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --from $(IMAGE) -f Containerfile.devel . -t $(IMAGE)-devel
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
debug: .build
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
	$(CMD_PREFIX) rm -f .build .push .ksimage boot-image/bootc.ks boot-image/l4t-bootc.iso
	$(CMD_PREFIX) buildah prune -f

images/rhel-ai/build/instructlab-nvidia: images/rhel-ai/Containerfile.ilab $(shell git ls-files | grep '^images/rhel-ai/overlays/ilab')
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(CUDA_BASE) -f Containerfile.ilab --layers=false --squash-all images/rhel-ai -t oci:$@

images/rhel-ai/build/deepspeed-trainer: images/rhel-ai/Containerfile.deepspeed
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(CUDNN_BASE) -f Containerfile.deepspeed --layers=false --squash-all images/rhel-ai -t oci:$@

images/rhel-ai/build/vllm: images/rhel-ai/Containerfile.vllm $(shell git ls-files | grep '^images/rhel-ai/overlays/vllm')
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always -f Containerfile.vllm --layers=false --squash-all images/rhel-ai -t oci:$@

images/rhel-ai/.build: images/rhel-ai/Containerfile images/rhel-ai/build/instructlab-nvidia images/rhel-ai/build/deepspeed-trainer images/rhel-ai/build/vllm
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(IMAGE) images/rhel-ai -t $(REGISTRY)/$(REPOSITORY):rhel-ai
	@touch $@

images/rhel-ai/.push: images/rhel-ai/.build
	$(CMD_PREFIX) $(RUNTIME) push $(REGISTRY)/$(REPOSITORY):rhel-ai
	@touch $@

.PHONY: rhel-ai
rhel-ai: images/rhel-ai/.push
