FROM BASE

# Perform an initial update and do some basic package installation
RUN dnf -y update \
 && dnf -y install \
    tmux \
    podman \
    curl \
    lm_sensors \
 && dnf -y clean all

# Install some useful developer tools and environment niceties
RUN dnf -y install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
 && dnf -y install \
    make \
    gcc \
    g++ \
    git \
    neovim \
    buildah \
    skopeo \
    python3.12 \
    python3.12-devel \
    python3.12-pip-wheel \
    fastfetch \
    btop \
 && dnf -y clean all

# Enable L4T/Jetpack 6 on the AGX Orin
COPY overlays/nvidia/ /
RUN dnf -y install https://repo-l4t.apps.okd.jharmison.com/jharmison-l4t-repo-9.rpm \
 && dnf config-manager --add-repo https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
 && dnf -y install \
    nvidia-container-toolkit-base \
	nvidia-jetpack-all \
	nvidia-jetpack-kmod \
 && dnf -y clean all

# Some helpful debugging output
COPY overlays/debug/ /
