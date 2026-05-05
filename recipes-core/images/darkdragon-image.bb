SUMMARY = "DarkDragon production-oriented image"
DESCRIPTION = "Project image for DarkDragon custom boards with the runtime package set and remote access enabled."
LICENSE = "MIT"

require recipes-core/images/core-image-base.bb

IMAGE_FEATURES += "ssh-server-openssh"

IMAGE_INSTALL:append = " \
    packagegroup-darkdragon-base \
"
