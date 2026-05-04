SUMMARY = "Simple hello world application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://hello.c \
    file://AutoHello.service \
    file://hello-ssh-login.sh \
"


S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "AutoHello.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_compile() {
    build_date="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    ${CC} ${CFLAGS} ${LDFLAGS} \
        -DHELLO_BUILD_DATE="\"${build_date}\"" \
        hello.c -o hello
}

do_compile[nostamp] = "1"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 hello ${D}${bindir}

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/AutoHello.service \
        ${D}${systemd_system_unitdir}/

    install -d ${D}${sysconfdir}/profile.d
    install -m 0644 ${WORKDIR}/hello-ssh-login.sh \
        ${D}${sysconfdir}/profile.d/hello-ssh-login.sh
}
