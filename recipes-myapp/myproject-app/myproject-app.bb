SUMMARY = "MyProject Raspberry Pi application"
DESCRIPTION = "Small service application used as the project-specific runtime entry point."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://myproject-app.c \
    file://myproject-app.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "myproject-app.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} ${WORKDIR}/myproject-app.c -o myproject-app
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 myproject-app ${D}${bindir}/myproject-app

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/myproject-app.service ${D}${systemd_system_unitdir}/myproject-app.service
}
