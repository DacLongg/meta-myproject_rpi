SUMMARY = "DarkDragon identity files"
DESCRIPTION = "OS release and MOTD files that brand the target as a DarkDragon image."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://issue \
    file://motd \
    file://os-release \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/issue ${D}${sysconfdir}/issue
    install -m 0644 ${WORKDIR}/motd ${D}${sysconfdir}/motd
    install -m 0644 ${WORKDIR}/os-release ${D}${sysconfdir}/os-release
}

FILES:${PN} += " \
    ${sysconfdir}/issue \
    ${sysconfdir}/motd \
    ${sysconfdir}/os-release \
"
