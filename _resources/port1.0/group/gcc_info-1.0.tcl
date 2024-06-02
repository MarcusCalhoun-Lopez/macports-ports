# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
#
# This PortGroup provides a repository to share information between various GCC and Libgcc ports
#
# Usage:
#
# PortGroup     gcc_info 1.0
#

# Libgcc versions that build
#     the versions must be in *ascending* order for gcc_build PG
#     the versions must be in the format 4.8, 4.9, 5, 6, etc.
#         GCC numbering scheme changes starting with version 5
#         see https://gcc.gnu.org/develop.html#num_scheme
#     the highest number must match `gcc_main_version` in _resources/port1.0/group/gcc_dependencies.tcl
options libgcc.versions
if { ${os.major} >= 10 || ${os.platform} ne "darwin" } {
    default libgcc.versions {4.5 6 7 8 9 10 11 12 13}
} else {
    default libgcc.versions {4.5 6 7}
}

# convenience option for most recent version of GCC that runs on this system
options libgcc.latest_version
default libgcc.latest_version {[lindex ${libgcc.versions} end]}

# utility function to get portname from GCC version
proc libgcc_from_version {v} {
    return libgcc[join [split ${v} .] ""]
}
