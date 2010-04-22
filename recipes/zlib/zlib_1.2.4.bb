DESCRIPTION = "Zlib Compression Library"
SECTION = "libs"
PRIORITY = "required"
HOMEPAGE = "http://www.gzip.org/zlib/"
LICENSE = "zlib"
PR = "r1"

SRC_URI = "http://www.zlib.net/zlib-${PV}.tar.bz2 \
"

DEPENDS = "libtool-cross"

inherit autotools_stage

BBCLASSEXTEND = "native"

oe_runconf() {
	./configure \
	--prefix=${prefix} \
	--eprefix=${exec_prefix} \
	--libdir=${libdir} \
	--includedir=${includedir}
}
