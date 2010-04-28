DESCRIPTION = "gnu-configize"
SECTION = "base"
LICENSE = "GPL"
DEPENDS = ""
INHIBIT_DEFAULT_DEPS = "1"

PR = "r1"

SRC_URI = "\
	file://gnu-configize.in"

S = "${WORKDIR}/config"

do_compile() {
	:
}

do_install () {
	install -d ${D}${datadir}/gnu-config \
		   ${D}${bindir}
	cat ${WORKDIR}/gnu-configize.in | \
		sed -e 's,@gnu-configdir@,${datadir}/gnu-config,g' \
		    -e 's,@autom4te_perllibdir@,${datadir}/autoconf,g' > ${D}${bindir}/gnu-configize
	# In the native case we want the system perl as perl-native can't have built yet
	if [ "${BUILD_ARCH}" != "${TARGET_ARCH}" ]; then
		cat ${WORKDIR}/gnu-configize.in | \
			sed -e 's,/usr/bin/perl,${bindir}/perl,g' > ${D}${bindir}/gnu-configize
	fi
	chmod 755 ${D}${bindir}/gnu-configize
	install -m 0644 ${CONFIG_GUESS} ${CONFIG_SUB} ${D}${datadir}/gnu-config/
}

PACKAGES = "${PN}"
FILES_${PN} = "${bindir} ${datadir}/gnu-config"

BBCLASSEXTEND = "native"
NATIVE_INSTALL_WORKS = "1"
