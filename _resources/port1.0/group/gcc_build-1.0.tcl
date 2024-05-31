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
# internal procedures
####################################################################################################################################
namespace eval gcc_build {}

proc gcc_build::callback {} {
}
port::register_callback gcc_build::callback
