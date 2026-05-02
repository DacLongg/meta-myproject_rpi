SUMMARY = "Raspberry Pi image for meta-myproject_rpi"
DESCRIPTION = "Project image for Raspberry Pi with SSH and the project application enabled."
LICENSE = "MIT"

require recipes-core/images/core-image-minimal.bb

IMAGE_FEATURES += "ssh-server-openssh debug-tweaks"

CORE_IMAGE_EXTRA_INSTALL += " \
    hello \
    myproject-app \
"
