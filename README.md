l4t-bootc
=========

This code base is designed to build a bootc image of RHEL 9.4 with Nvidia Jetpack 6.0 / Linux for Tegra (l4t) pieces enabled, and ensure it's consumable by helping to build a boot `.iso` for the Nvidia Jetson AGX Orin Development Kit that will refer to the bootc image and wire up a basic user.

Part of the future design goals for the repo include a few other images pushed to different tags with different use-cases baked into them, to enable `bootc switch`ing the host.

Usage
-----

You need to have access to the Jetpack/l4t RPMs via a normal RPM repo. I've hosted one on my private network, and you can host your own if you have an OKD or OpenShift cluster and the RPMs themselves by using the [l4t-repo](https://github.com/jharmison-redhat/l4t-repo) code base. There's ways to host them without OKD/OpenShift, but I happen to have a cluster so I like to use it for things like this - you can adapt the code there appropriately to host them.

You need your container runtime signed into two different container image registries - `registry.redhat.io` and wherever you plan on pushing this image when it's built. You'll also want, if your registry requires authentication (as mine does for most images, including this one), an [auth.json](https://github.com/containers/image/blob/main/docs/containers-auth.json.5.md) file adjacent to the `Makefile` that includes an auth token for at least pulling the image that this repo is designed to push. This is embedded into the image so that it can pull the image for installation and updates.

In order to build the kickstarted boot `.iso`, you'll need `rhel-9.4-aarch64-boot.iso` downloaded from the [Red Hat Customer Portal](https://access.redhat.com/downloads/content/419/ver=/rhel---9/9.4/aarch64/product-software). I downloaded mine with my personal [free Individual Developer Account](https://developers.redhat.com/about). Place this in the `boot-image/` directory, adjacent to `bootc.ks.tpl`.

One final thing you need configured is the capability to run entitled RHEL builds with `podman`. If you're on a subscribed RHEL system, this will just work. I'm working from Fedora, where I was able to install `subscription-manager` and then register [as if I were on a RHEL system](https://access.redhat.com/solutions/253273) and then entitled builds mostly just work - with one catch: They don't work for cross-arch builds, which we're doing here for the AGX Orin. I was pointed to some configuration to enable this [here](https://github.com/redhat-developer/podman-desktop-redhat-account-ext/issues/95), so thanks to the Red Hatters who understood what I needed to do and how to get me over that hump. Cross-arch entitled builds from Fedora is kind of a strange place to be, I think, and Googling wasn't helping me.

With all of that in place, you can `make REGISTRY=${REGISTRY_HOST_NAME} REPOSITORY=${NAMESPACE}/${REPOSITORY}` to run to build the bootc image in multi-arch podman and roll a thin boot `.iso` that points to the image you've pushed. If you want to burn the boot `.iso` to a flash drive, you can use `dd` yourself or `make burn DEST=/dev/sdX` where `sdX` is replaced with the device ID of your flash drive.

Boot your Jetson from the flash drive, and be prepared to remove the flash drive as - for some reason - the AGX Orin doesn't like to add new EFI boot entries above external drives that have recently been plugged in.
