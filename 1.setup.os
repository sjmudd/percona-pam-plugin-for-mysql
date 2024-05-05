#!/bin/sh
#
# OS specific packages needed for the build
#

. $(dirname $0)/common_code.sh

set +u
# tags not used yet, but might be needed to be version dependent.
mysql_tag=$1
percona_tag=$2
set -u

msg_info "Starting: mysql_tag=$mysql_tag, percona_tag=$percona_tag"
if [ -z "$mysql_tag" -o -z "$percona_tag" ]; then
	msg_info "TAGS are currently unused but may be needed in the future when building handling the build of different versions"
fi

ARCH=$(uname -m) # to handle x86_64 or aarch64
CENTOS7_RPMS="
	bind-utils
	bison
	cmake3
	cyrus-sasl-devel libaio-devel
	devtoolset-11-binutils
	devtoolset-11-gcc
	devtoolset-11-gcc-c++
	git
	libcurl-devel
	libtirpc-devel
	libudev-devel
	ncurses-devel
	numactl-devel
	openldap-devel
	openssl-devel
	pam-devel
	perl
	perl-Data-Dumper
	perl-Env
	perl-JSON
	rpcgen
	time"

CENTOS8_RPMS="
	bind-utils
	bison
	cmake
	cyrus-sasl-devel libaio-devel
	gcc-toolset-12-annobin-annocheck
	gcc-toolset-12-annobin-plugin-gcc
	gcc-toolset-12-binutils
	gcc-toolset-12-gcc
	gcc-toolset-12-gcc-c++
	git
	libcurl-devel
	libtirpc-devel
	libudev-devel
	ncurses-devel
	numactl-devel
	openldap-devel
	openssl-devel
	pam-devel
	perl
	perl-JSON
	rpcgen
	time"

OEL8_RPMS="
	bind-utils
	bison
	cmake
	cyrus-sasl-devel libaio-devel
	gcc-toolset-12-annobin-annocheck
	gcc-toolset-12-annobin-plugin-gcc
	gcc-toolset-12-binutils
	gcc-toolset-12-gcc
	gcc-toolset-12-gcc-c++
	git
	libcurl-devel
	libtirpc-devel
	libudev-devel
	ncurses-devel
	numactl-devel
	openldap-devel
	openssl-devel
	pam-devel
	perl
	perl-JSON
	rpcgen
	time"

CENTOS9_RPMS="
	bind-utils
	bison
	cmake
	cyrus-sasl-devel libaio-devel
	gcc-toolset-12-annobin-annocheck
	gcc-toolset-12-annobin-plugin-gcc
	gcc-toolset-12-binutils
	gcc-toolset-12-dwz
	gcc-toolset-12-gcc
	gcc-toolset-12-gcc-c++
	git
	libcurl-devel
	libtirpc-devel
	libudev-devel
	ncurses-devel
	numactl-devel
	openldap-devel
	openssl-devel
	pam-devel
	perl
	perl-JSON
	rpcgen
	time"

COMMON_RPMS="
	rpm-build
	util-linux
	wget"

# yum is stupid and won't generate errors if a package is not installed or found!
#yum='yum --setopt=skip_missing_names_on_install=False'
yum=yum

#
# install the base repository
#
msg_info "########################################################"
msg_info "#     base repository setup for $OSNAME..."
msg_info "########################################################"

$yum update -y
$yum install -y 'dnf-command(config-manager)'

msg_info "Enabling distro specific repos..."
case $OSNAME in
centos7)
	$yum install -y centos-release-scl
	$yum install -y epel-release
	yum-config-manager --enable centos-release-scl
	yum-config-manager --enable epel-release
	;;
centos8)
	yum config-manager --set-enabled powertools;;
ol8)	yum config-manager --set-enabled ol8_codeready_builder;;
centos9)
	yum config-manager --set-enabled crb;;
ol9)	yum config-manager --set-enabled ol9_codeready_builder;;
*)	log_error 1 "Unable to figure out repos to enable for OSNAME $OSNAME"
esac

#
# install required packages
#
msg_info "########################################################"
msg_info "#     Installing required rpms for $OSNAME"
msg_info "########################################################"

case $OSNAME in
centos7|ol7)
	PACKAGES=$CENTOS7_RPMS;;
centos8)
	PACKAGES=$CENTOS8_RPMS;;
ol8)	PACKAGES=$OEL8_RPMS;;
centos9|ol9)
	PACKAGES=$CENTOS9_RPMS;;
*)	msg_error 1 "PACKAGES not configured for OS $OSNAME"
esac

$yum install -y $PACKAGES $COMMON_RPMS

#
# Post rpm install fixes
#

case $OSNAME in
centos7)
    # ensure devtoolset-11 is enabled when building
    if ! grep /opt/rh/devtoolset-11/enable /etc/bashrc; then
        msg_info "### Patching /etc/bashrc to enable devtoolset-11"
        msg_info "source /opt/rh/devtoolset-11/enable" >> /etc/bashrc
    else
        msg_info "### /etc/bashrc already patched to enable devtoolset-11"
    fi
    ;;
centos8|centos9|ol8)
    # patch gcc-toolset to avoid build problems
    if ! [ -e /opt/rh/gcc-toolset-12/root/usr/lib/gcc/$ARCH-redhat-linux/12/plugin/gcc-annobin.so ]; then
        msg_info "### Symlinking gcc-annobin.so to annobin.so"
       	(
            pushd /opt/rh/gcc-toolset-12/root/usr/lib/gcc/$ARCH-redhat-linux/12/plugin
            if [ $OSNAME = centos8 ]; then
                ln -s annobin.so gcc-annobin.so
            elif [ $OSNAME = centos9 ]; then
                for f in annobin.so annobin.so.0.0.0 gcc-annobin.so gcc-annobin.so.0.0.0; do
		    test -e $f || ln -s gts-annobin.so.0.0.0 $f
                done
            elif [ $OSNAME = ol8 ]; then
                msg_info "no handling needed for ol8"
	    fi
	    popd
        )
    else
        msg_info "### Symlink gcc-annobin.so already exists"
    fi

    # ensure gcc-toolset-12 is enabled when building
    if ! grep /opt/rh/gcc-toolset-12/enable ~/.bashrc; then
        msg_info "### Patching ~/.bashrc to enable gcc-toolset-12"
        msg_info "source /opt/rh/gcc-toolset-12/enable" >> ~/.bashrc
    else
        msg_info "### ~/.bashrc is already patched to enable gcc-toolset-12"
    fi
    ;;
*)  msg_info "No postfixes for OSNAME $OSNAME"
esac

msg_info "########################################################"
msg_info "#     $OSNAME preparation complete                    #"
msg_info "########################################################"
