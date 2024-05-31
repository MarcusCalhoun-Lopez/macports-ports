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

# `description` and `long_description` behave a little strangely when `default` is used
description             the GNU compiler collection
long_description        The GNU compiler collection,

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

# GCC language (actually front end) support based on `${version}`
# each front end can have up to four parts
#     value for `--enable-languages`
#.    name of language (front end but not language if blank)
#     GCC version front end was introduced (all versions if does not exist)
#     GCC version front end was removed (still exists if does not exist)
foreach arch {arm64 x86_64 i386 ppc ppc64} {
    options gcc.languages.${arch}
}
default gcc.languages.arm64     {c c++ objc obj-c++ fortran lto jit java}
default gcc.languages.x86_64    {c c++ objc obj-c++ fortran lto jit java}
# jit compiler is not building on i386 systems
#     see https://trac.macports.org/ticket/61130
default gcc.languages.i386      {c c++ objc obj-c++ fortran lto     java}
default gcc.languages.ppc       {c c++ objc obj-c++ fortran lto     java}
default gcc.languages.ppc64     {c c++ objc obj-c++ fortran lto     java}

# GCC front end information
# essentially an associative array
#     index is the value for `--enable-languages`
#     value can have 1-3 parts
#    .    name of language (front end but not language if blank)
#         GCC version front end was introduced (all versions if does not exist)
#         GCC version front end was removed (still exists if does not exist)
options gcc.languages_info
default gcc.languages_info      {c C c++ C++ objc Objective-C obj-c++ Objective-C++ fortran Fortran lto {"" 4.6} jit {"" 8} java {Java 4.3 6}}

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

    # set `--enable-languages`
    array set languages_info [option gcc.languages_info] ; # gcc.languages_info as an associative array
    set languages [list] ; # record front ends that are actually languages (for port description)
    foreach arch [option configure.build_arch] {
        set frontends [list]
        foreach frontend [option gcc.languages.${arch}] {
            set info $languages_info(${frontend})
            if { [llength ${info}] == 1 ||
                 ([llength ${info}] == 2 && [vercmp [lindex ${info} 1] <= ${version}]) ||
                 ([llength ${info}] == 3 && [vercmp [lindex ${info} 1] <= ${version}] && [vercmp ${version} < [lindex ${info} 2]])
             } {
                lappend frontends [lindex ${frontend} 0]
                if { [lindex ${info} 0] ne "" && ${arch} eq [option configure.build_arch] } {
                    lappend languages [lindex ${info} 0]
                }
            }
        }
        configure.args-prepend          --enable-languages=[join ${frontends} ","]
    }

    # append languages to `long_description`
    switch [llength ${languages}] {
        1       { long_description-append including a front end for [lindex ${languages} 0]. }
        2       { long_description-append including front ends for [lindex ${languages} 0] and [lindex ${languages} end]. }
        default { long_description-append including front ends for [join [lrange ${languages} 0 end-1] ", "], and [lindex ${languages} end]. }
    }
}
port::register_callback gcc_build::callback
