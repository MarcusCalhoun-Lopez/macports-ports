# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
#
# This PortGroup supports building GCC
#
# Usage:
#
# PortGroup     gcc_build 1.0
#

PortGroup   active_variants             1.1
PortGroup   compiler_blacklist_versions 1.0
PortGroup   conflicts_build             1.0
PortGroup   gcc_info                    1.0
PortGroup   select                      1.0

####################################################################################################################################
# tweak MacPorts defaults
####################################################################################################################################

default maintainers     {nomaintainer}

default homepage        {https://gcc.gnu.org/}
default categories      {lang}

# an exception in the license allows dependents to not be GPL
default license         {{GPL-3+ Permissive}}

# primary releases
default master_sites    {https://ftpmirror.gnu.org/gcc/gcc-${version}/${gcc.tag} \
                         https://mirror.its.dal.ca/gnu/gcc/gcc-${version}/${gcc.tag} \
                         https://mirrors.kernel.org/gnu/gcc/gcc-${version}/${gcc.tag} \
                         https://www.mirrorservice.org/sites/ftp.gnu.org/gnu/gcc/gcc-${version}/${gcc.tag} \
                         https://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.gnu.org/gcc/gcc-${version}/${gcc.tag} \
                         https://mirror.yongbok.net/gnu/gcc/gcc-${version}/${gcc.tag} \
                         http://mirror.koddos.net/gcc/releases/gcc-${version}/${gcc.tag} \
                         ftp://ftp.gwdg.de/pub/linux/gcc/releases/gcc-${version}/${gcc.tag} \
                         ftp://gcc.ftp.nluug.nl/mirror/languages/gcc/releases/gcc-${version}/${gcc.tag} \
                         ftp://gcc.gnu.org/pub/gcc/releases/gcc-${version}/${gcc.tag} \
                         gnu:gcc/gcc-${version}${gcc.tag}}

default distname        {gcc-${version}}

default livecheck.type  {regex}
default livecheck.url   {http://mirror.koddos.net/gcc/releases/}
default livecheck.regex {gcc-([option gcc.major].\[0-9.\]+)/}

####################################################################################################################################
# define GCC options
####################################################################################################################################

# tag for `master_sites` (see https://guide.macports.org/chunked/reference.phases.html)
options gcc.tag
default gcc.tag {}

# stripped version of `${version}` corresponding to MacPorts ports (e.g. 4.8, 4.9, 5, 6, etc.)
# GCC numbering scheme changes starting with version 5
#     see https://gcc.gnu.org/develop.html#num_scheme
options gcc.major
default gcc.major   {[expr {[vercmp ${version} >= 5] ? [lindex [split ${version} .-] 0] : [join [lrange [split ${version} .-] 0 1] .]}]}

# suffix to add to files to void conflict with various GCC ports
options gcc.suffix
default gcc.suffix  {[expr {${name} eq "gcc-devel" ? "devel" : ${gcc.major}}]}

####################################################################################################################################
# internal procedures
####################################################################################################################################
namespace eval gcc_build {}

proc gcc_build::callback {} {
    global prefix name subport version

    if { [vercmp ${version} >= 5] } {
        use_xz      yes
    } else {
        use_bzip2   yes
    }
}
port::register_callback gcc_build::callback
