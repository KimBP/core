# This class exists to provide information about the targets that
# may be needed by other classes and/or recipes. If you add a new
# target this will probably need to be updated.

#
# Returns information about 'what' for the named target 'target'
# where 'target' == "<arch>-<os>"
#
# 'what' can be one of
# * target: Returns the target name ("<arch>-<os>")
# * endianess: Return "be" for big endian targets, "le" for little endian
# * bits: Returns the bit size of the target, either "32" or "64"
# * libc: Returns the name of the c library used by the target
#
# It is an error for the target not to exist.
# If 'what' doesn't exist then an empty value is returned
#
def get_siteinfo_list(d):
       target = bb.data.getVar('HOST_ARCH', d, 1)

       targetinfo = {\
              "powerpc-unknown-linux-gnu": "endian-big bit-32 common-linux common-glibc powerpc-common",\
              "powerpc-fpu-linux-gnu": "endian-big bit-32 common-linux common-glibc powerpc-common",\
              "powerpc-nofpu-linux-gnu": "endian-big bit-32 common-linux common-glibc powerpc-common",\
              "x86_64-unknown-linux-gnu":  "endian-little bit-64 common-linux common-glibc",\
              "x86_64-pc-linux-gnu":       "endian-little bit-64 common-linux common-glibc",\
              "i386-pc-mingw32":           "endian-little bit-32 common-mingw ix86-common",\
              "i486-pc-mingw32":           "endian-little bit-32 common-mingw ix86-common",\
              "i586-pc-mingw32":           "endian-little bit-32 common-mingw ix86-common",\
              "i686-pc-mingw32":           "endian-little bit-32 common-mingw ix86-common",\
              }
       if target in targetinfo:
               info = targetinfo[target].split()
               info.append(target)
               info.append("common")
               return info
       else:
               bb.error("Information not available for target '%s'" % target)


#
# Define which site files to use. We check for several site files and
# use each one that is found, based on the list returned by get_siteinfo_list()
#
# Search for the files in the following directories:
# 1) ${BBPATH}/site (in reverse) - app specific, then site wide
# 2) ${FILE_DIRNAME}/site-${PV}         - app version specific
#
def siteinfo_get_files(d):
       import bb, os

       sitefiles = ""

       # Determine which site files to look for
       sites = get_siteinfo_list(d)
       sites.append("common");

       # Check along bbpath for site files and append in reverse order so
       # the application specific sites files are last and system site
       # files first.
       path_bb = bb.data.getVar('BBPATH', d, 1)
       for p in (path_bb or "").split(':'):
               tmp = ""
               for i in sites:
                       fname = os.path.join(p, 'site', i)
                       if os.path.exists(fname):
                               tmp += fname + " "
               sitefiles = tmp + sitefiles;

       # Now check for the applications version specific site files
       path_pkgv = os.path.join(bb.data.getVar('FILE_DIRNAME', d, 1), "site-" + bb.data.getVar('PV', d, 1))
       for i in sites:
               fname = os.path.join(path_pkgv, i)
               if os.path.exists(fname):
                       sitefiles += fname + " "

       bb.debug(1, "SITE files " + sitefiles);
       return sitefiles

#
# Export CONFIG_SITE to the enviroment. The autotools will make use
# of this to determine where to load in variables from. This is a
# space seperate list of shell scripts processed in the order listed.
#
export CONFIG_SITE = "${@siteinfo_get_files(d)}"


def siteinfo_get_endianess(d):
       info = get_siteinfo_list(d)
       if 'endian-little' in info:
              return "le"
       elif 'endian-big' in info:
              return "be"
       bb.error("Site info could not determine endianess for target")

def siteinfo_get_bits(d):
       info = get_siteinfo_list(d)
       if 'bit-32' in info:
              return "32"
       elif 'bit-64' in info:
              return "64"
       bb.error("Site info could not determine bit size for target")

#
# Make some information available via variables
#
SITEINFO_ENDIANESS  = "${@siteinfo_get_endianess(d)}"
SITEINFO_BITS       = "${@siteinfo_get_bits(d)}"


