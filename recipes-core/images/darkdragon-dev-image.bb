SUMMARY = "DarkDragon development image"
DESCRIPTION = "Development image with debug-friendly features, test tools, and sample applications."
LICENSE = "MIT"

require recipes-core/images/darkdragon-image.bb

IMAGE_FEATURES += "debug-tweaks package-management"

IMAGE_INSTALL:append = " \
    packagegroup-darkdragon-dev \
"
