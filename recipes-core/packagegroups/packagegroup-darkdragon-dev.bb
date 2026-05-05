SUMMARY = "Developer-focused package set for DarkDragon images"
DESCRIPTION = "Debug, inspection, and sample packages used on development images."
LICENSE = "MIT"
PR = "r1"

inherit packagegroup

RDEPENDS:${PN} = " \
    hello \
    less \
    procps \
    rsync \
    strace \
    tcpdump \
    vim \
"
