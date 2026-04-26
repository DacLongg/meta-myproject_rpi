SUMMARY = "Simple hello world application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://hello.c \
    file://AutoHello.service \
"


S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "AutoHello.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} hello.c -o hello
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 hello ${D}${bindir}

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/AutoHello.service \
        ${D}${systemd_system_unitdir}/
}

