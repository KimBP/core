DESCRIPTION = "Miscellaneous files for the base system."
LICENSE = "GPL"

SECTION = "base"
PRIORITY = "required"

INC_PR = ".0"

SRC_URI = " \
           file://motd \
           file://host.conf \
           file://profile \
           file://fstab \
           file://issue.net \
           file://issue \
           file://dot.bashrc \
           file://dot.profile "

# Basic filesystem directories (adheres to FHS)
dirs1777 = "/tmp \
	   ${localstatedir}/volatile/lock \
	   ${localstatedir}/volatile/tmp"
dirs2775 = "/home \
	    ${localstatedir}/local"
dirs755 = "${bindir} \
	   ${sbindir} \
	   ${libdir} \
	   ${libexecdir} \
	   ${includedir} \
	   ${sysconfdir} \
	   ${sysconfdir}/default \
	   ${sysconfdir}/skel \
	   ${prefix} \
	   ${docdir} \
	   ${datadir} \
	   ${infodir} \
	   ${mandir} \
	   ${datadir}/misc \
	   ${localstatedir} \
	   ${localstatedir}/backups \
	   ${localstatedir}/lib \
	   ${localstatedir}/lib/misc \
	   ${localstatedir}/spool \
	   ${localstatedir}/volatile \
	   ${localstatedir}/volatile/cache \
	   ${localstatedir}/volatile/lock/subsys \
	   ${localstatedir}/volatile/log \
	   ${localstatedir}/volatile/run \
	   /sys \
	   /boot \
	   /dev \
	   /dev/pts \
	   /mnt \
	   /proc \
	   /root \
	   /srv \
	   /media \
	   /media/card \
	   /media/cf \
	   /media/net \
	   /media/ram \
	   /media/hdd "

volatiles = "cache run log lock tmp"

do_install () {

	# Install directories

	for d in ${dirs755}; do
		install -m 0755 -d ${D}$d
	done
	for d in ${dirs1777}; do
		install -m 1777 -d ${D}$d
	done
	for d in ${dirs2775}; do
		install -m 2755 -d ${D}$d
	done
	for d in ${volatiles}; do
                if [ -d ${D}${localstatedir}/volatile/$d ]; then
                        ln -sf volatile/$d ${D}/${localstatedir}/$d
                fi
	done

	# Install files

        echo ${DISTRO}-host > ${D}${sysconfdir}/hostname

 	install -m 0644 ${WORKDIR}/issue ${D}${sysconfdir}/issue
        install -m 0644 ${WORKDIR}/issue.net ${D}${sysconfdir}/issue.net

        echo -n "${DISTRO} " >> ${D}${sysconfdir}/issue
        echo "\n \l" >> ${D}${sysconfdir}/issue
        echo >> ${D}${sysconfdir}/issue
        
        echo -n "${DISTRO} " >> ${D}${sysconfdir}/issue.net
        echo "%h" >> ${D}${sysconfdir}/issue.net
        echo >> ${D}${sysconfdir}/issue.net
        
        install -m 0644 ${WORKDIR}/fstab ${D}${sysconfdir}/fstab
        install -m 0644 ${WORKDIR}/profile ${D}${sysconfdir}/profile
        install -m 0755 ${WORKDIR}/dot.profile ${D}${sysconfdir}/skel/.profile
        install -m 0755 ${WORKDIR}/dot.bashrc ${D}${sysconfdir}/skel/.bashrc
        install -m 0644 ${WORKDIR}/motd ${D}${sysconfdir}/motd
        install -m 0644 ${WORKDIR}/host.conf ${D}${sysconfdir}/host.conf

        ln -sf /proc/mounts ${D}${sysconfdir}/mtab
}

