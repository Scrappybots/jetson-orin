include ../../Makefile.common

CUDA_BASE := nvcr.io/nvidia/cuda:12.3.2-devel-ubi9
CUDNN_BASE := nvcr.io/nvidia/cuda:12.1.1-cudnn8-devel-ubi9
VLLM_COMMIT := 3dc28190247ee1fd4d228d5860559e1417ee0451

CUDA_OVERLAY := $(shell git ls-files | grep '^overlays/cuda-repos')
VLLM_OVERLAY := $(shell git ls-files | grep '^overlays/vllm')
WRAPPER_OVERLAY := $(shell git ls-files | grep '^overlays/wrappers')
.PHONY: all
all: .push

build/instructlab-nvidia: Containerfile.ilab $(CUDA_OVERLAY)
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(CUDA_BASE) -f $< --layers=false --squash-all . -t oci:$@

build/deepspeed-trainer: Containerfile.deepspeed
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(CUDNN_BASE) -f $< --layers=false --squash-all . -t oci:$@

overlays/vllm/build/workspace/setup.py:
	$(CMD_PREFIX) mkdir -p $(@D) && cd $(@D) && { \
		git clone https://github.com/IBM/vllm . || git fetch ; \
	}
	$(CMD_PREFIX) cd $(@D) && git branch rhel-ai $(VLLM_COMMIT) && git switch rhel-ai && rm -rf .git

build/vllm: Containerfile.vllm $(CUDA_OVERLAY) $(VLLM_OVERLAY) overlays/vllm/build/workspace/setup.py
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always -f $< --layers=false --squash-all . -t oci:$@

.build: Containerfile build/instructlab-nvidia build/deepspeed-trainer build/vllm $(WRAPPER_OVERLAY)
	$(CMD_PREFIX) $(RUNTIME) build --security-opt label=disable --arch aarch64 --pull=always --from $(IMAGE) . -t $(REGISTRY)/$(REPOSITORY):rhel-ai
	@touch $@

.push: .build
	$(CMD_PREFIX) $(RUNTIME) push $(REGISTRY)/$(REPOSITORY):rhel-ai
	@touch $@

