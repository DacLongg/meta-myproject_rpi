FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:darkdragon-rpi3 = " \
    file://darkdragon-bcm2710.dtsi \
    file://darkdragon-rpi-family.dtsi \
    file://darkdragon-rpi3-board.dtsi \
    file://darkdragon-rpi3.dts \
"

do_configure:append:darkdragon-rpi3() {
    install -d ${S}/arch/arm/boot/dts
    install -m 0644 ${WORKDIR}/darkdragon-bcm2710.dtsi \
        ${S}/arch/arm/boot/dts/darkdragon-bcm2710.dtsi
    install -m 0644 ${WORKDIR}/darkdragon-rpi-family.dtsi \
        ${S}/arch/arm/boot/dts/darkdragon-rpi-family.dtsi
    install -m 0644 ${WORKDIR}/darkdragon-rpi3-board.dtsi \
        ${S}/arch/arm/boot/dts/darkdragon-rpi3-board.dtsi
    install -m 0644 ${WORKDIR}/darkdragon-rpi3.dts \
        ${S}/arch/arm/boot/dts/darkdragon-rpi3.dts

    if ! grep -q "darkdragon-rpi3.dtb" ${S}/arch/arm/boot/dts/Makefile; then
        printf '\ndtb-$(CONFIG_ARCH_BCM2835) += darkdragon-rpi3.dtb\n' \
            >> ${S}/arch/arm/boot/dts/Makefile
    fi
}
