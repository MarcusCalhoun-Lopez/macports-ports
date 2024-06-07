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
PortGroup   muniversal                  1.1
PortGroup   select                      1.0

####################################################################################################################################
# tweak MacPorts defaults
####################################################################################################################################

# from several of the GCC ports
# still relevant?
# TODO: Possibly disable bootstrap with appropriate configure flags.
#       the problem is that libstdc++'s configure script tests for tls support
#       using the running compiler (not gcc for which libstdc++ is being built).
#       Thus when we build with clang, we get a mismatch
# http://trac.macports.org/ticket/36116
#compiler.blacklist-append {clang < 425}
#configure.args-append --disable-bootstrap
#build.target        all

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

default configure.dir   {${workpath}/build}
default configure.cmd   {${workpath}/${worksrcdir}/configure} ; # `${worksrcpath}/configure}` does not work with muniversal PG

default build.dir       {${configure.dir}}
default build.target    {bootstrap-lean}

default destroot.target {install install-info-host}

# try to keep flags as clean as possible
# most importantly, `-stdlib` would be passed on to the bootstrap compiler if present
default configure.cflags        {}
default configure.cxxflags      {}
default configure.pipe          {}
default configure.cxx_stdlib    {}

# allow configure scripts to set CPP variants to something like `$(CC) -arch ... -E`
# `/usr/bin/cpp` does not work
rename portconfigure::configure_get_compiler portconfigure::real_gcc_configure_get_compiler
proc portconfigure::configure_get_compiler {type {compiler {}}} {
    if { ${type} eq "cpp" } {
        return ""
    } else {
        return [portconfigure::real_gcc_configure_get_compiler ${type} ${compiler}]
    }
}

# muniversal PG cannot merge .la files
default destroot.delete_la_files    {yes}

# TODO it is not entirely clear why this is needed
#     see https://github.com/macports/macports-ports/commit/dd17e940bc80e9902dc1969ebf27e4de00d246b0
default configure.ccache    {no}

default livecheck.type  {regex}
default livecheck.url   {http://mirror.koddos.net/gcc/releases/}
default livecheck.regex {gcc-([option gcc.major].\[0-9.\]+)/}

####################################################################################################################################
# tweak PortGroup defaults
####################################################################################################################################

# cross-compiling on macOS does not seem to be well supported
# if host!=build, build fails due to lack of build spec file
#     see https://gcc.gnu.org/onlinedocs/gcc/Spec-Files.html
# if host=build!=target, build fails due to lack of `host_detect_local_cpu`
default muniversal.run_binaries     {yes}
foreach arch {arm64 x86_64 i386 ppc ppc64} {
    if { [option muniversal.can_run.${arch}] && [option muniversal.is_cross.${arch}] } {
        default muniversal.is_cross.${arch} {no}
    }
}

# always add `--build=...`
default triplet.add_build   {all}

# ensure directory names use same names ae `${configure.build_arch}`
foreach arch {arm64 x86_64 i386 ppc ppc64} {
    default triplet.cpu.${arch}      "${arch}"
}
unset   arch

# do not add `-arch ...` to compiler flags
default muniversal.arch_flag        {no}
# append `-arch ...` to compiler namea
default muniversal.arch_compiler    {yes}

default select.group {[expr {${subport} eq ${name} ? "gcc" : ""}]}
default select.file  {[expr {${subport} eq ${name} ? "${filespath}/mp-${name}" : ""}]}

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
#         name of language (front end but not language if blank)
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

# GCC dependencies based on `${version}`
# each dependency can have up to three parts
#     dependency
#     GCC version dependency started being necessary (all versions if does not exist)
#.    GCC version dependency was ceased bing necessary (still necessary if does not exist)
options gcc.depends_build
default gcc.depends_build   {{port:texinfo 10}}

options gcc.depends_lib
default gcc.depends_lib     {port:cctools \
                            {path:lib/pkgconfig/cloog-isl.pc:cloog 4.6 5} \
                            port:gmp \
                            {path:lib/pkgconfig/isl.pc:isl 6} \
                            {port:isl18 4.9 6} \
                            {port:isl14 4.8 4.9} \
                            port:ld64 \
                            port:libiconv \
                            {port:libmpc 4.5} \
                            port:mpfr \
                            {port:ppl 4.6 4.8}
                            port:zlib \
                            {port:zstd 10}}

options gcc.depends_run
default gcc.depends_run     {port:gcc_select}

# convenience options for include directory stricture (gcc for Libgcc and gccX for GCC version X)
options gcc.gcc_name
default gcc.gcc_name    {[expr {${subport} eq ${name} ? ${name} : "gcc"}]}

# convenience options for library directory strictures (libgcc for Libgcc and gccX for GCC version X)
options gcc.libgcc_name
default gcc.libgcc_name {[expr {${subport} eq ${name} ? ${name} : "libgcc"}]}

# SDK to be used by GCC if configure.sdkroot is not empty
#     avoid current, rapidly changing SDKS and use the generic one instread
options gcc.sdkroot
default gcc.sdkroot {[regsub {MacOSX[1-9]+\.[0-9]+\.sdk} ${configure.sdkroot} {MacOSX.sdk}]}

# tools to be used by GCC
options gcc.as
default gcc.as  {${prefix}/bin/as}
options gcc.ld
default gcc.ld  {${prefix}/bin/ld}
options gcc.ar
default gcc.ar  {${prefix}/bin/ar}

# recent GCC versions use rpath
#     see https://trac.macports.org/ticket/65472
#     see https://trac.macports.org/ticket/63115
options gcc.rpath
default gcc.rpath   {${prefix}/lib/libgcc}

# GCC configure options
#     each option can have up to three parts
#         value for `configure` script
#         GCC version option was introduced (all versions if does not exist)
#         GCC version option was removed (not removed if does not exist)
#
# `--disable-tls` does not limit functionality
#     it only determines how std::call_once works
#     see https://lists.macports.org/pipermail/macports-dev/2017-August/036209.html
# we should be using `--with-build-sysroot`
#     using `--with-sysroot` changes the behavior of the installed gcc to look in that sysroot by default instead of /
#     using `--with-build-sysroot` is supposed to be used during the build but not impact the installed product
#     unfortunately, the build fails because the value doesn't get plumbed everywhere it is supposed to
#     see https://trac.macports.org/ticket/53726
#     see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=79885
# for `--with-build-config=bootstrap-debug`,
#     see https://trac.macports.org/ticket/47410
#     see https://trac.macports.org/ticket/51245
options gcc.pre_args
default gcc.pre_args    {}
options gcc.args
default gcc.args    {   --libdir=${prefix}/lib/${gcc.libgcc_name} \
                        --includedir=${prefix}/include/${gcc.gcc_name} \
                        --infodir=${prefix}/share/info \
                        --mandir=${prefix}/share/man \
                        {--datarootdir=${prefix}/share/gcc-${gcc.suffix}    4.5} \
                        {--datadir=${prefix}/share/${name}                  4.3 4.5} \
                        --with-local-prefix=${prefix} \
                        --with-system-zlib \
                        --disable-nls \
                        --program-suffix=-mp-${gcc.suffix} \
                        --with-gxx-include-dir=${prefix}/include/${gcc.gcc_name}/c++ \
                        --with-gmp=${prefix} \
                        --with-mpfr=${prefix} \
                        {--with-mpc=${prefix}               4.5} \
                        {--with-isl=${prefix}               6} \
                        {--with-isl=${prefix}/libexec/isl18 4.9 6} \
                        {--with-isl=${prefix}/libexec/isl14 4.8 4.9} \
                        {--disable-isl-version-check        4.8 5} \
                        {--with-cloog=${prefix}             4.6 5} \
                        {--disable-cloog-version-check      4.6 5} \
                        {--enable-cloog-backend=isl         4.6 4.8} \
                        {--with-ppl=${prefix}               4.6 4.8} \
                        {--disable-ppl-version-check        4.6 4.8} \
                        {--with-zstd=${prefix}      10} \
                        {--enable-checking=release  10} \
                        {--enable-stage1-checking   4.3 10} \
                        {--enable-lto               4.6} \
                        {--enable-libstdcxx-time    4.6} \
                        {--with-build-config=bootstrap-debug    4.5} \
                        --with-bugurl=https://trac.macports.org/newticket \
                        {--enable-host-shared   8} \
                        {--with-darwin-extra-rpath=${gcc.rpath} 10} \
                        --with-libiconv-prefix=${prefix} \
                        --disable-tls \
                    }
options gcc.post_args
default gcc.post_args   {[expr {${configure.sdkroot} eq "" ? "" : "--with-sysroot=${gcc.sdkroot}"}] \
                        --with-pkgversion="MacPorts\ ${name}\ ${version}_${revision}${portvariants}" \
                        }

# convenience option to determine if subport is a full Libgcc installation
options libgcc.is_full
default libgcc.is_full {[expr {${subport} ne ${name} && (${subport} eq "libgcc-devel") || ${gcc.major} eq ${libgcc.latest_version}}]}

# Libgcc library names to keep if subport is not full Libgcc installation
options libgcc.keep
default libgcc.keep     {}

# ensure configure script and Makefile.in find the right tools
# here, we define more values than are necessary (or used)
#     however, there seems to be no harm
# muniversal PG handles CPP_FOR_BUILD, CXXCPP_FOR_BUILD, CPPFLAGS_FOR_BUILD, CC_FOR_BUILD, CXX_FOR_BUILD
options gcc.exports
default gcc.exports {AR=${gcc.ar} \
                     AR_FOR_BUILD=${gcc.ar} \
                     AR_FOR_TARGET=${gcc.ar} \
                     AS=${gcc.as} \
                     AS_FOR_BUILD=${gcc.as} \
                     AS_FOR_TARGET=${gcc.as} \
                     LD=${gcc.ld} \
                     LD_FOR_BUILD=${gcc.ld} \
                     LD_FOR_TARGET=${gcc.ld} \
                     NM=${prefix}/bin/nm \
                     NM_FOR_BUILD=${prefix}/bin/nm \
                     NM_FOR_TARGET=${prefix}/bin/nm \
                     OBJDUMP=${prefix}/bin/objdump \
                     OBJDUMP_FOR_TARGET=${prefix}/bin/objdump \
                     RANLIB=${prefix}/bin/ranlib \
                     RANLIB_FOR_BUILD=${prefix}/bin/ranlib \
                     RANLIB_FOR_TARGET=${prefix}/bin/ranlib \
                     STRIP=${prefix}/bin/strip \
                     STRIP_FOR_TARGET=${prefix}/bin/strip \
                     OTOOL=${prefix}/bin/otool \
                     OTOOL64=${prefix}/bin/otool
                    }

# if they exist, libraries from which to stip debug symbols to supress debugger warnings
#     see https://trac.macports.org/ticket/34831
#     see https://github.com/macports/macports-ports/commit/f1c52ce5b1946eaaed2d69f192fe6f7e3e62935e
options libgcc.strip
default libgcc.strip {libgcc_ext.10.4.dylib libgcc_ext.10.5.dylib}

# MacPorts-specific values that should be exported to all phases of the build
#     see https://trac.macports.org/ticket/68683
#     see https://github.com/gcc-mirror/gcc/commit/b410cf1dc056aab195c5408871ffca932df8a78a
options gcc.macports_exports
default gcc.macports_exports    {DISABLE_MACPORTS_AS_CLANG_SEARCH=1 \
                                DISABLE_XCODE_AS_CLANG_SEARCH=1}

####################################################################################################################################
# internal procedures
####################################################################################################################################
namespace eval gcc_build {}

# utility function to add dependencies based on `${version}`
proc gcc_build::add_dependencies {type depends} {
    foreach dep ${depends} {
        if { [llength ${dep}] == 1 ||
             ([llength ${dep}] == 2 && [vercmp [lindex ${dep} 1] <= [option version]]) ||
             ([llength ${dep}] == 3 && [vercmp [lindex ${dep} 1] <= [option version]] && [vercmp [option version] < [lindex ${dep} 2]])
         } {
            depends_${type}-delete [lindex ${dep} 0]
            depends_${type}-append [lindex ${dep} 0]
        }
    }
}

# utility function to add args based on `${version}`
proc gcc_build::add_args {args gcc.args} {
    foreach arg ${gcc.args} {
        if { [llength ${arg}] == 1 ||
             ([llength ${arg}] == 2 && [vercmp [lindex ${arg} 1] <= [option version]]) ||
             ([llength ${arg}] == 3 && [vercmp [lindex ${arg} 1] <= [option version]] && [vercmp [option version] < [lindex ${arg} 2]])
         } {
            configure.${args}-delete [lindex ${arg} 0]
            configure.${args}-append [lindex ${arg} 0]
        }
    }
}

# unfortunate hack to add variants after Portfile is run
#     see https://github.com/macports/macports-base/blob/master/src/port1.0/portutil.tcl
#     see https://github.com/macports/macports-base/blob/master/src/macports1.0/macports.tcl
rename ::eval_variants ::real_gcc_eval_variants
proc eval_variants {variations} {
    # TODO: do not add for Libgcc?
    if { [vercmp [option gcc.major] >= 10] } {
        variant stdlib_flag description {Enable stdlib command line flag to select c++ runtime} {}
        # libcxx is unavailable on PPC
        foreach arch [list arm64 x86_64 i386] {
            if { ${arch} in [option muniversal.architectures] } {
                default_variants-delete +stdlib_flag
                default_variants-append +stdlib_flag
                break;
            }
        }
    }
    uplevel ::real_gcc_eval_variants ${variations}
}

proc gcc_build::callback {} {
    global prefix name subport version

    if { [vercmp ${version} >= 5] } {
        use_xz      yes
    } else {
        use_bzip2   yes
    }

    # set dependencies
    if { ${subport} eq ${name} } {
        ######################
        # GCC compiler subport
        ######################

        gcc_build::add_dependencies build [option gcc.depends_build]
        gcc_build::add_dependencies lib   [option gcc.depends_lib]
        gcc_build::add_dependencies run   [option gcc.depends_run]

        # depend on earliest possible Libgcc
        #     found Libgcc is then responsible for later Libgcc dependencies
        if { ${subport} ne "gcc-devel" } {
            set libgcc_dep  "path:share/doc/libgcc/README:libgcc"
        } else {
            set libgcc_dep  "port:libgcc-devel"
        }
        foreach v [lrange [option libgcc.versions] 0 end-1] {
            if { [vercmp ${v} >= [option gcc.major]] } {
                set libgcc_dep port:[libgcc_from_version ${v}]
                break
            }
        }
        depends_run-delete ${libgcc_dep}
        depends_run-append ${libgcc_dep}
    } else {
        ######################
        # Libgcc subport
        ######################

        # even if little of it is retained, building Libgcc requires the same dependencies as GCC
        gcc_build::add_dependencies build [list {*}[option gcc.depends_build] {*}[option gcc.depends_lib]]
        if { [exists depends_lib] } {
            # avoid duplicates
            depends_build-delete    {*}[option depends_lib]
        }

        if { ![option libgcc.is_full] } {
            # depend on earliest possible subsequent Libgcc
            set libgcc_dep  "path:share/doc/libgcc/README:libgcc"
            foreach v [lrange [option libgcc.versions] 0 end-1] {
                if { [vercmp ${v} > [option gcc.major]] } {
                    set libgcc_dep port:[libgcc_from_version ${v}]
                    break
                }
            }
            depends_run-delete ${libgcc_dep}
            depends_run-append ${libgcc_dep}
        }
    }

    # GCC uses neither headers nor libraries from these dependencies
    depends_skip_archcheck-delete gcc_select ld64 cctools
    depends_skip_archcheck-append gcc_select ld64 cctools

    # TODO: GCC is marked Permissive, so is the following necessary or a historical artifact?
    license_noconflict-delete  gmp mpfr ppl libmpc zlib
    license_noconflict-append  gmp mpfr ppl libmpc zlib

    # TODO: are all these necessary for all versions of GCC and is an actual fix available?
    #
    # `conflicts_build` is a workaround not a fix (see https://trac.macports.org/ticket/67412#comment:18)
    # best fix: work with upstream to ensure `-I` are in the right order (see https://trac.macports.org/ticket/67412#comment:13)
    # hack fix: avoid -I${prefix}/include and temporarily copy necessary header files (from e.g. gmp) from ${prefix}/include to an isolated location
    #
    # for binutils,
    #     see https://github.com/macports/macports-ports/commit/f2c9687dbe5da91bc44628bec6a3370e17c89ae8
    # for gdb,
    #     see https://trac.macports.org/ticket/67412
    # for libunwind-headers,
    #     see https://trac.macports.org/ticket/43869
    #     see https://trac.macports.org/ticket/57198
    conflicts_build-delete binutils gdb libunwind-headers
    conflicts_build-append binutils gdb libunwind-headers

    if { [option libgcc.is_full] } {
        # this subport has been marked as providing a full Libgcc installation
        if { ${subport} ne "libgcc-devel" } {
            conflicts-delete  libgcc-devel
            conflicts-append  libgcc-devel
        } else {
            conflicts-delete  [libgcc_from_version [option libgcc.latest_version]]
            conflicts-append  [libgcc_from_version [option libgcc.latest_version]]
        }
    }

    # set `--configure` arguments
    gcc_build::add_args pre_args    [option gcc.pre_args]
    gcc_build::add_args args        [option gcc.args]
    gcc_build::add_args post_args   [option gcc.post_args]

    # ensure configure script finds libc++ headers
    if { [variant_exists stdlib_flag] && [variant_isset stdlib_flag] } {
        # libcxx is unavailable on PPC
        foreach arch [list arm64 x86_64 i386] {
            configure.args.${arch}-delete   --with-gxx-libcxx-include-dir=${prefix}/libexec/${name}/libc++/include/c++/v1
            configure.args.${arch}-append   --with-gxx-libcxx-include-dir=${prefix}/libexec/${name}/libc++/include/c++/v1
        }
        depends_run-delete  port:${name}-libcxx
        depends_run-append  port:${name}-libcxx
    }

    # ensure GFortran (part of GCC) works properly with -m32/-m64
    #     fortran mod and "header" files cannot be merged
    #     GFortran will only look in arch specific directories via `-fintrinsic-modules-path` if multilib is enabled
    # needed for Libgcc since multilib affects installed header files
    configure.args.arm64-delete             --disable-multilib
    configure.args.arm64-append             --disable-multilib
    foreach {arch1 arch2} [list x86_64 i386 ppc64 ppc] {
        if { ${arch1} ni [option muniversal.architectures] } {
            configure.args.${arch2}-delete  --disable-multilib
            configure.args.${arch2}-append  --disable-multilib
        }
        if { ${arch2} ni [option muniversal.architectures] } {
            configure.args.${arch1}-delete  --disable-multilib
            configure.args.${arch1}-append  --disable-multilib
        }
    }

    # see description of `gcc.exports`
    foreach e [option gcc.exports] {
        configure.env-delete    ${e}
        configure.env-append    ${e}
    }

    # see description of `gcc.macports_exports`
    foreach e [option gcc.macports_exports] {
        # as these exports are MacPorts-specific, `configure` does not recognize them, so
        #     add them to build environment as well
        configure.env-delete    ${e}
        configure.env-append    ${e}
        build.env-delete        ${e}
        build.env-append        ${e}
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

post-patch {
    # add to "the list of variables to export in the environment when configuring any subdirectory"
    # see https://gcc.gnu.org/git/?p=gcc.git;a=blob;f=Makefile.in;hb=HEAD
    set makefile [open "${worksrcpath}/Makefile.in" a]
    puts ${makefile} ""
    puts ${makefile} "# MacPorts additions"
    foreach e [option gcc.macports_exports] {
        puts ${makefile} "BASE_EXPORTS += ${e}; export ${e};"
    }
    close ${makefile}
}

post-destroot {
    if { [vercmp ${gcc.major} >= 10] } {
        # ensure all dylibs in destroot have our extra rpath
        #     see https://trac.macports.org/ticket/65503
        foreach dylib [ exec find ${destroot}${prefix} -type f -and -name "*.dylib" ] {
            ui_debug "Ensuring DYLIB '${dylib}' has RPATH '${gcc.rpath}'"
            # install_name_tool returns a failure if the dylib already has the entry
            #     we don't want that here so force final status to be true...
            system "install_name_tool -add_rpath ${gcc.rpath} ${dylib} > /dev/null 2>&1 ; true"
        }
    }

    if { ${subport} eq ${name} } {
        ######################
        # GCC compiler subport
        ######################

        # avoid extraneous file
        #     see https://github.com/macports/macports-ports/commit/f1c52ce5b1946eaaed2d69f192fe6f7e3e62935e
        # it is not clear which GCC versions require it, but `file delete` works fine for nonexistent files
        # for more information on share/info/dir,
        #     see https://bbs.archlinux.org/viewtopic.php?pid=420728#p420728
        file delete ${destroot}${prefix}/share/info/dir

        # avoid conflict between various GCC ports
        foreach file [glob ${destroot}${prefix}/share/{info,man/man7}/*] {
            file rename ${file} "[file rootname ${file}]-mp-${gcc.suffix}[file extension ${file}]"
        }

        # while there can be multiple versions of these runtimes in a single
        #     process, it is not possible to pass objects between different versions,
        #     so we simplify this by having the libgcc port provide the newest version
        #     of these runtimes for all versions of gcc to use.
        # see http://trac.macports.org/ticket/35770
        # see http://trac.macports.org/ticket/38814
        foreach dylib [glob -directory ${destroot}${prefix}/lib/${name} -tails *.*.dylib] {
            # `${dylib}` is a versioned shared library
            file delete ${destroot}${prefix}/lib/${name}/${dylib}
            ln -s ${prefix}/lib/libgcc/${dylib} ${destroot}${prefix}/lib/${name}/${dylib}
        }

        # allow merge to handle different architectures
        foreach dylib [glob -directory ${destroot}${prefix}/lib/${name} -tails *.{dylib,so,a,o}] {
            # `${dylib}` can be merged into a fat binary
            foreach archdir [glob -nocomplain ${destroot}${prefix}/lib/${name}/{arm64,x86_64,i386,ppc,ppc64}/] {
                if { [file exists ${archdir}/${dylib}] } {
                    delete ${archdir}/${dylib}
                    ln -s ../${dylib} ${archdir}/${dylib}
                }
            }
        }
    } else {
        ######################
        # Libgcc subport
        ######################

        # delete most files
        # keep library files (either all of them or ones specified by libgcc.keep)
        # keep header files but only for full Libgcc installation
        #     see https://trac.macports.org/ticket/54766 and
        #     see https://trac.macports.org/ticket/53194
        file delete -force ${destroot}${prefix}/bin
        file delete -force ${destroot}${prefix}/share
        file delete -force ${destroot}${prefix}/libexec
        foreach archdir [glob -nocomplain ${destroot}${prefix}/lib/libgcc/{arm64,x86_64,i386,ppc,ppc64}/] {
            # allow merge to handle different architectures
            file delete -force ${archdir}
        }
        if { ![option libgcc.is_full] } {
            # this subport is not a full Libgcc installation, so only keep the specified files
            file delete -force ${destroot}${prefix}/include
            foreach dylib [glob -directory ${destroot}${prefix}/lib/libgcc -tails *] {
                if { ${dylib} ni [option libgcc.keep] } {
                    file delete -force ${destroot}${prefix}/lib/libgcc/${dylib}
                }
            }
        }

        # see description of `libgcc.strip`
        foreach dylib [option libgcc.strip] {
            # not all files exist in all Libgcc versions
            # see https://trac.macports.org/ticket/65055
            if { [file exists ${destroot}${prefix}/lib/libgcc/${dylib}] } {
                system "${prefix}/bin/strip -x ${destroot}${prefix}/lib/libgcc/${dylib}"
            }
        }

        # TODO: is this fix still needed?
        # for binary compatibility with binaries that linked against the old libstdcxx port
        # see https://github.com/macports/macports-ports/commit/ac5a416fd8dc537e38f9c55b39e5e9e873c3454d
        ln -s libgcc/libstdc++.6.dylib ${destroot}${prefix}/lib/libstdc++.6.dylib

        # TODO: fix inconsistent creation of README
        switch -- [option gcc.suffix] {
            10 -
            11 {
                set doc_dir ${destroot}${prefix}/share/doc/${subport}
                xinstall -m 755 -d ${doc_dir}
                system "echo ${subport} provides additional runtime > ${doc_dir}/README"
            }
            8  -
            12 {
                set doc_dir ${destroot}${prefix}/share/doc/${subport}
                xinstall -m 755 -d ${doc_dir}
                system "echo ${subport} provides no runtime > ${doc_dir}/README"
            }
            -devel {
                xinstall -d ${destroot}${prefix}/share/doc/libgcc
                system "echo 'libgcc runtime is provided by ${subport}' > ${destroot}${prefix}/share/doc/libgcc/README"
            }
        }
    }
}

pre-activate {
    if { ${libgcc.is_full} } {
        #
        # this subport has been marked as providing a full Libgcc installation
        # the port that provides the bulk of Libgcc changes as new versions of GCC are released, yet
        #     the old full Libgcc port may still install files and depend on the new full Libgcc port
        # to ease upgrades, apply activate hack on any older Libgcc port that attempted to provide full Libgcc
        #     see https://trac.macports.org/wiki/PortfileRecipes#deactivatehack
        #
        # libgcc-devel and latest working libgcc\d+ should be marked as conflicting, so this libgcc-devel should not unintentionally deactivate full libgcc\d+ installation
        #
        set fl ${prefix}/lib/libgcc/libgcc_s.dylib ; # see https://gcc.gnu.org/onlinedocs/gccint/Libgcc.html
        if { [file exists ${fl}] } {
            set provider [registry_file_registered ${fl}]
            if { [regexp {^libgcc(\d+|-devel)$} ${provider}] && ${provider} ne ${subport} } {
                if { ![catch {set installed [lindex [registry_active ${provider}] 0]}] } {
                    if { [vercmp [lindex ${installed} 1] < ${version}] } {
                        registry_deactivate_composite ${provider} "" [list ports_nodepcheck 1]
                    }
                }
            }
        }
    }
}

proc gcc_build::stub_callback {} {
    if { [option subport] eq [option name] || [option libgcc.is_full] || [option libgcc.keep] ne "" } { return }

    # this Libgcc subport does not install any library files
    # it may install library files for different values of `${os.major}`, but not this one
    # the subport builds all of Libgcc and then proceed to delete everything except a README file
    # while correct, it is highly inefficient
    # we also want to avoid multiple `if` statements throughout this PG to accommodate this situation
    # this PG is complicated enough
    # one solution is to have this subport defined in different Portfiles depending on`${os.major}`
    # however, this would be potentially quite confusing
    #
    # as a compromise, hack away through previously set values to mimic a stub port

    # clear dependencies
    foreach type [list fetch extract patch build lib run test] {
        if { [exists depends_${type}] } {
            global depends_${type}
            unset depends_${type}
        }
    }

    # prevent search for unnecessary and potentially nonexistent extract program
    uplevel 2 "proc portextract::extract_start {args} {}"

    # set all phases (including pre- and post-) to do nothing
    foreach phase {fetch extract patch configure build destroot test} {
        global org.macports.${phase}
        foreach part {pre procedure post} {
            foreach p [ditem_key [set org.macports.${phase}] ${part}] {
                if {[info procs user${p}] ne ""} {
                    set proc_name user${p}
                } else {
                    set proc_name ${p}
                }
                uplevel 2 "proc ${proc_name} {{args \"\"}} {}"
            }
        }
    }

    platforms       any
    supported_archs	noarch

    # depend on earliest possible subsequent Libgcc
    set libgcc_dep  "path:share/doc/libgcc/README:libgcc"
    foreach v [lrange [option libgcc.versions] 0 end-1] {
        if { [vercmp ${v} > [option gcc.major]] } {
            set libgcc_dep port:[libgcc_from_version ${v}]
            break
        }
    }
    depends_run ${libgcc_dep}

    distfiles

    destroot {
        xinstall -d ${destroot}${prefix}/share/doc/${subport}
        system "echo ${subport} provides no runtime > ${destroot}${prefix}/share/doc/${subport}/README"
    }
}
port::register_callback gcc_build::stub_callback
# bypass muniversal PG
rename universal_setup real_gcc_universal_setup
proc universal_setup {args} {
    if { [option subport] ne [option name] && ![option libgcc.is_full] && [option libgcc.keep] eq "" } { return }
    real_gcc_universal_setup ${args}
}
