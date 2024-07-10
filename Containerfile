FROM registry.redhat.io/rhel9/rhel-bootc:9.4

ARG KVER=5.14.0-427.18.1.el9_4.aarch64

# Perform some basic package installation
COPY overlays/auth/ /
RUN --mount=target=/var/cache,type=tmpfs --mount=target=/var/cache/dnf,type=cache,id=dnf-cache \
    dnf -y install kernel-${KVER} kernel-headers-${KVER} \
 && dracut -vf /usr/lib/modules/${KVER}/initramfs.img ${KVER} \
 && dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
 && dnf -y install \
      tmux \
      podman \
      curl \
      lm_sensors \
      btop

# Enable L4T/Jetpack 6 on the AGX Orin
COPY overlays/nvidia/ /
RUN --mount=target=/var/cache,type=tmpfs --mount=target=/var/cache/dnf,type=cache,id=dnf-cache \
    dnf -y install https://repo-l4t.apps.okd.jharmison.com/jharmison-l4t-repo-9.rpm \
 && dnf config-manager --add-repo https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
 && dnf -y install \
      nvidia-container-toolkit-base \
      nvidia-jetpack-all \
      nvidia-jetpack-kmod \
      nvtop

# Some helpful debugging output
#COPY overlays/debug/ /

# Basic user configuration with nss-altfiles
COPY overlays/users/ /
RUN useradd -m core \
 && chown core:core /usr/local/ssh/core.keys

# Fix up initrd/bootloader issues
