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

ARG SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCgGljB+CYmrCZ5ATJBdkCXOYNSdcXSSmq4TZsgzLNsvyaOI+arOOtZ0JAwYmg/wPHck0AaHP4rFhB4PohRbn9Z8n2lRlEtCQcKhgb1ZVSa2KFlWfk+/eCxdkx0QBZx2h0kQzOYhJx4fC35H1gsdK5fmRGZ4a1r+DjPpmJGcsuNptz/eoKhIa9jGaM7gFFKLgJYQ5cOeNJIXc1tMQCMXwPERIPSYRwPh8LcJ0B+f1hZml2FSNItxYUapykvWD7tPWHANSqVf00SIVjDQFrjoUZibj2JofDwdBepIktMoe0MDgV8n60CulCVGktfx7EObd4nq5eMhCziU3bwkjUsRYfTyCmSTUz82qFns7R0eG+48XftHziQGa+tgNehafrHLLLPgnt9lPeeIqkTxupRx+pl299AC9qKqw0WBSuWc7JQZy3rSQbh/w1dBll+t32mgn4NSND7ED/6knmWCXMnM9NeXH8SHmBJRELe/annM1ahCm0LRXVh3i/yLzPqPacjzIPW3JMpLEGnsBtFHNp7hCcfzhfH52ecqVzK1ZAkKZH4r3LOpX+i20Dq61AeATaiiqKokrLDmz16hkRhmiF6pvatBGVy8Lqnipht7RxnLTMl+is2hcBtYYvTY6BPAs2ImgnuSWdbHdBC6ag4IDZzv+XsHGBncQ/h8duv+IQ9W1b+zQ== jharmison@redhat.com"
# Configure our user
RUN groupadd -g 1000 core \
 && useradd -c 'core' -d /var/home/core -u 1000 -g 1000 -m -G wheel -s /bin/bash core \
 && mkdir -p /var/home/core/.ssh \
 && echo "$SSH_KEY" > /var/home/core/.ssh/authorized_keys \
 && chmod -R u=rwX,g=,o= /var/home/core/.ssh \
 && chown -R 1000:1000 /var/home/core \
 && chcon -R -u unconfined_u -r object_r -t ssh_home_t /var/home/core/.ssh
