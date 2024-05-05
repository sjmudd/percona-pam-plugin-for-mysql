#!/bin/bash
#
# build environment for building Percona PAM rpms for MySQL
#

set -u

myname=$(basename $0)
# which which user we are building as in logging as we mix root and a build user.
set +u
myuser=$(if [ -n "$USER" ]; then echo /$USER; else echo /$(id -un); fi)
set -u

BUILD_USER=rpmbuild
BUILD_HOME=/home/rpmbuild

# try to figure out our hostname for logging
# - containers may or may not have a hostname and it may be short or not
get_hostname () {
	local hostname

	if which hostname >/dev/null 2>&1; then
		hostname=$(hostname -s)
	elif [ -n "$HOSTNAME" ]; then
		hostname="$HOSTNAME"
	else
		hostname=""
	fi

	if [ -n "$hostname" ]; then
		echo "$hostname "
	fi
}

# get a version from a release tag such as mysql-8.4.0 --> 8.4.0
get_mysql_version () {
	local mysql_tag=$1

	echo $mysql_tag | sed -e 's/mysql-//'
}

# get a version from a release tag such as Percona-Server-8.3.0-1 --> 8.3.0
get_percona_version () {
	local percona_tag=$1

	echo $percona_tag | sed -e 's/Percona-Server-//' -e 's/-[0-9]*$//'
}

myhostname=$(get_hostname)

# generate a UTC timestamp
utc_timestamp () {
	TZ=UTC date +%Y-%m-%dT%H:%M:%S
}

msg_info () {
	echo "$(utc_timestamp) $myhostname$myname$myuser[$$]: $@"
}

msg_error () {
	local rc=${1:-1}
	msg_info "ERROR: $@"

	exit $rc
}

# return 1 if we need to provide a boost version, 0 otherwise
# - for the moment we don't try to guess
need_boost_version () {
        local mysql_tag="$1"
        local mysql_version=$(get_mysql_version $mysql_tag)
        local major_version=$(echo $mysql_version | sed -e 's/\.[0-9]*$//')

        if [ "$major_version" = "8.0" ]; then
                echo 1
        else
                echo 0
        fi
}

# check the shell
if [ $(basename $SHELL) != bash ]; then
	msg_error 1 "Expecting the shell to be bash, but found $SHELL, exiting"
fi

# only do inside container build scripts
if [ $(basename $0) != build_one ]; then
	# set OSNAME / MAJOR_VERSION based on /etc/os-release
	set +u
	if [ -z "$ID" ]; then
		if [ ! -e /etc/os-release ]; then
			msg_error 1 "Can not determine the OS properly as /etc/os-release is missing"
		fi
		. /etc/os-release

		case $ID in
		almalinux|ol|rocky|centos|rhel)
			# convert to a single digit if there's a decimal part
			MAJOR_VERSION=$(echo $VERSION_ID | sed -e 's/\..*//')
			OSNAME=${ID}${MAJOR_VERSION}
			;;
		*)
			msg_error 1 "Unrecognised OS: $NAME ($ID $VERSION_ID). Provide a patch to support your linux version if needed."
		esac
	fi
	set -u
fi
