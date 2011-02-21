#RECIPE_ARCH = "${RECIPE_ARCH_MACHINE}"

require conf/kernel.conf

inherit kernel-common kernel-modules-strip

EXTRA_OEMAKE += "CROSS_COMPILE=${TARGET_PREFIX}"

RECIPE_OPTIONS += "kernel_defconfig"
DEFCONFIG_FILE ?= "${SRCDIR}/defconfig"
DEFCONFIG = "${@d.getVar('RECIPE_OPTION_kernel_defconfig', 1) or ''}"

kernel_do_configure () {
    if [ -e "${DEFCONFIG_FILE}" ]; then
	cp "${DEFCONFIG_FILE}" "${S}/.config"
        yes '' | oe_runmake oldconfig
    else
	if [ -n "${DEFCONFIG}" ] ; then
	    oe_runmake ${DEFCONFIG}
	else
	    die "No default configuration for ${MACHINE} available."
	fi
    fi
}

do_configure () {
    kernel_do_configure
}

#do_menuconfig() {
#    export TERMWINDOWTITLE="${PN} Kernel Configuration"
#    export SHELLCMDS="make menuconfig"
#    ${TERMCMDRUN}
#    if [ $? -ne 0 ]; then
#        echo "Fatal: '${TERMCMD}' not found. Check TERMCMD variable."
#        exit 1
#    fi
#}
#do_menuconfig[nostamp] = "1"
#addtask menuconfig after do_patch

kernel_do_compile () {
    oe_runmake include/linux/version.h
    oe_runmake ${RECIPE_OPTION_kernel_imagetype}

    if (grep -q -i -e '^CONFIG_MODULES=y$' .config); then
	oe_runmake modules
    else
	oenote "no modules to compile"
    fi

    # Check if scripts/genksyms exists and if so, build it
    if [ -e scripts/genksyms/ ]; then
	oe_runmake SUBDIRS="scripts/genksyms"
    fi
}

do_compile () {
    kernel_do_compile
}

KERNEL_UIMAGE_DEPENDS = "${@['', 'u-boot-mkimage-native']['${RECIPE_OPTION_kernel_imagetype}' == 'uImage']}"
DEPENDS += "${KERNEL_UIMAGE_DEPENDS}"

RECIPE_OPTIONS += "kernel_uimage \
    kernel_uimage_entrypoint kernel_uimage_loadaddress kernel_uimage_name"
KERNEL_UIMAGE_DEPENDS_RECIPE_OPTION_kernel_uimage = "u-boot-mkimage-native"
DEPENDS += "${KERNEL_UIMAGE_DEPENDS}"
DEFAULT_CONFIG_kernel_uimage = "0"
DEFAULT_CONFIG_kernel_uimage_entrypoint = "20008000"
DEFAULT_CONFIG_kernel_uimage_loadaddress = "${RECIPE_OPTION_kernel_image_entrypoint}"
DEFAULT_CONFIG_kernel_uimage_name = "${DISTRO}/${PV}/${MACHINE}"

kernel_do_compile_append_RECIPE_OPTION_kernel_uimage () {
    ENTRYPOINT=${RECIPE_OPTION_kernel_uimage_entrypoint}
    if test -n "${UBOOT_ENTRYSYMBOL}"; then
	ENTRYPOINT=`${HOST_PREFIX}nm ${S}/vmlinux | \
	    awk '$3=="${RECIPE_OPTION_kernel_uimage_entrypoint}" {print $1}'`
    fi

    if test -e arch/${ARCH}/boot/compressed/vmlinux ; then
	${OBJCOPY} -O binary -R .note -R .comment \
	-S arch/${ARCH}/boot/compressed/vmlinux linux.bin
	mkimage -A ${UBOOT_ARCH} -O linux -T kernel -C none \
	-a ${RECIPE_OPTION_kernel_uimage_loadaddress} \
	-e $ENTRYPOINT \
	-n ${RECIPE_OPTION_kernel_uimage_name} \
	-d linux.bin arch/${ARCH}/boot/uImage
	rm -f linux.bin

    else
	${OBJCOPY} -O binary -R .note -R .comment -S vmlinux linux.bin
	rm -f linux.bin.gz
	gzip -9 linux.bin
	mkimage -A ${UBOOT_ARCH} -O linux -T kernel -C gzip \
	-a ${RECIPE_OPTION_kernel_uimage_loadaddress} \
	-e $ENTRYPOINT \
	-n ${RECIPE_OPTION_kernel_uimage_name} \
	-d linux.bin.gz arch/${ARCH}/boot/uImage
	rm -f linux.bin.gz
    fi
}

UIMAGE_KERNEL_OUTPUT = ""
UIMAGE_KERNEL_OUTPUT_append_RECIPE_OPTION_kernel_uimage = "arch/${ARCH}/boot/uImage"
KERNEL_OUTPUT += "${UIMAGE_KERNEL_OUTPUT}"

RECIPE_OPTIONS += "kernel_dtc kernel_dtc_flags kernel_dtc_source"
DEFAULT_CONFIG_kernel_dtc_flags = "-R 8 -p 0x3000"
DEFAULT_CONFIG_kernel_dtc_source = "arch/${KERNEL_ARCH}/boot/dts/${MACHINE}.dts"

kernel_devicetree () {
    if [ -n "${KERNEL_DEVICETREE}" ] ; then
        echo "${KERNEL_DEVICETREE}"
    elif [ "${RECIPE_OPTION_kernel_dtc}" = "1" ] ; then
        echo `basename ${RECIPE_OPTION_kernel_dtc_source} .dts`.dtb
    fi
}

kernel_do_compile_append_RECIPE_OPTION_kernel_dtc () {
    devicetree=`kernel_devicetree`
    if [ -n "$devicetree" ] ; then
        scripts/dtc/dtc -I dts -O dtb ${RECIPE_OPTION_kernel_dtc_flags} \
            -o $devicetree ${RECIPE_OPTION_kernel_dtc_source}
    fi
}

kernel_do_install () {
    install -d ${D}${bootdir}
    install -m 0644 ${KERNEL_IMAGE} ${D}${bootdir}/${KERNEL_IMAGE_FILENAME}
    install -m 0644 .config ${D}${bootdir}/config

    devicetree=`kernel_devicetree`
    if [ -n "$devicetree" ] ; then
        install -m 0644 $devicetree ${D}${bootdir}/${KERNEL_DEVICETREE_FILENAME}
    fi

    if (grep -q -i -e '^CONFIG_MODULES=y$' .config); then
	oe_runmake DEPMOD=echo INSTALL_MOD_PATH="${D}" modules_install
        rm ${D}/lib/modules/*/build ${D}/lib/modules/*/source
    else
	oenote "no modules to install"
    fi

    install -d ${D}${bootdir}
    for kernel_output in ${KERNEL_OUTPUT} ; do
	install -m 0644 ${kernel_output} ${D}${bootdir}/
    done

    install -d ${D}/kernel
    cp -fR scripts ${D}/kernel/

    install_kernel_headers
}

install_kernel_headers () {
    mkdir -p ${D}${includedir}
    oe_runmake headers_install INSTALL_HDR_PATH=${D}${includedir}
}

do_install () {
    kernel_do_install
}

PACKAGES = "${PN} ${PN}-vmlinux ${PN}-dev ${PN}-headers ${PN}-modules ${PN}-dtb"

FILES_${PN} = "${bootdir}/${KERNEL_IMAGE_FILENAME}"
FILES_${PN}-dtb = "${bootdir}/${KERNEL_DEVICETREE_FILENAME}"
FILES_${PN}-vmlinux = "${bootdir}/vmlinux"
FILES_${PN}-dev = "${bootdir}/System.map ${bootdir}/Module.symvers \
    ${bootdir}/config"
FILES_${PN}-headers = "${includedir}"
FILES_${PN}-modules = "/lib/modules"

# FIXME: implement auto-package-kernel-modules.bbclass to split out
# modules into separate packages

# Support checking the kernel size since some kernels need to reside
# in partitions with a fixed length or there is a limit in
# transferring the kernel to memory
addtask sizecheck before do_install after do_compile
do_sizecheck () {
}
do_sizecheck_append_RECIPE_OPTION_kernel_maxsize () {
    size=`ls -l ${KERNEL_IMAGE} | awk '{ print $5}'`
    if [ "$size" -ge "${RECIPE_OPTION_kernel_maxsize}" ]; then
	die  "This kernel (size=$size > ${RECIPE_OPTION_kernel_maxsize}) is too big for your device. Please reduce the size of the kernel, fx. by making more of it modular."
    fi
}


addtask deploy after do_fixup before do_build
do_deploy[dirs] = "${IMAGE_DEPLOY_DIR} ${S}"

do_deploy() {
    install -m 0644 ${KERNEL_IMAGE} \
	${IMAGE_DEPLOY_DIR}/${KERNEL_IMAGE_DEPLOY_FILE}
    md5sum <${KERNEL_IMAGE} \
	>${IMAGE_DEPLOY_DIR}/${KERNEL_IMAGE_DEPLOY_FILE}.md5

    devicetree=`kernel_devicetree`
    if [ -n "$devicetree" ] ; then
	install -m 0644 $devicetree \
	    ${IMAGE_DEPLOY_DIR}/${KERNEL_DEVICETREE_DEPLOY_FILE}
	md5sum <$devicetree \
	    >${IMAGE_DEPLOY_DIR}/${KERNEL_DEVICETREE_DEPLOY_FILE}.md5
    fi

    cd ${IMAGE_DEPLOY_DIR}
    if [ -n "${KERNEL_IMAGE_DEPLOY_LINK}" ] ; then
	rm -f ${KERNEL_IMAGE_DEPLOY_LINK}
	ln -sf ${KERNEL_IMAGE_DEPLOY_FILE} ${KERNEL_IMAGE_DEPLOY_LINK}
    fi
    if [ -n "${KERNEL_DEVICETREE_DEPLOY_LINK}" ] ; then
	rm -f ${KERNEL_DEVICETREE_DEPLOY_LINK}
	ln -sf ${KERNEL_DEVICETREE_DEPLOY_FILE} ${KERNEL_DEVICETREE_DEPLOY_LINK}
    fi
}