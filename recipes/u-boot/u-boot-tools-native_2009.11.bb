require ${PN}.inc

PR_append = ".0"

SRC_URI = "ftp://ftp.denx.de/pub/u-boot/u-boot-${PV}.tar.bz2"
S = "${WORKDIR}/u-boot-${PV}"
