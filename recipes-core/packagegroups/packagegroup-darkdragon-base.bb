SUMMARY = "Base runtime package set for DarkDragon targets"
DESCRIPTION = "Core runtime packages that every DarkDragon product image should ship."
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

RDEPENDS:${PN} = " \
    bash \
    bluez5 \
    ca-certificates \
    darkdragon-release \
    ethtool \
    i2c-tools \
    iproute2 \
    iputils \
    kernel-modules \
    myproject-app \
    openssh-sftp-server \
    tzdata \
    iw \
    wpa-supplicant \
"
