# Percona Pam Plugin for MySQL

- Thanks to Oracle for providing: https://github.com/mysql/mysql-server.
- Thanks to Percona for providing: https://github.com/percona/percona-server.

You could use Percona Server if you want some of the extra features
provided against the upstream MySQL community version.  However, you may
want to run the Percona PAM plugin on the upstream MySQL server itself.
There are reasons to do both. You choose.

Both code bases use GPL software so this is perfectly acceptable.

This repo provides a process to build the Percona PAM plugin on the
MySQL server and create the rpms that are needed.  Intended to be used
on RHEL 7/8/9 and "compatible" distributions.

## Requirements

To perform the builds and configuration requires the use of docker.  This
is to ensure a reproducible build can be created and the same process can
be run against multiple OS versions and MySQL/Percona server combinations.

Note: the host running docker does not need to run on a RHEL or compatible
OS.  I have done the builds on Ubuntu.  Other Linux distros supporting
Docker should work too.

## Usage

Building requires the use of the upstream *git tags*, taken from the
corresponding repos.  These tags are currently expected to follow the
following format:
- `mysql-X.Y.Z` for version `X.Y.Z` of MySQL Server
- `Percona-Server-X.Y.Z-R` for version `X.Y.Z` of Percona Server

On the *build host* call `build_one` with appropriate parameters to
create the spec file and run the build.

Required parameters are:
- `<mysql-tag>` to build against, e.g. `mysql-8.0.37`, `mysql-8.4.0`
- `<percona-tag>` to build against, e.g. `Percona-Server-8.0.36-28`, `Percona-Server-8.3.0-1`
- if building against 8.0 you must also provide the version of boost libraries to use. e.g. `1.77.0` for MySQL 8.0.36
- the build process will build binary and source rpms named something like `percona-pam-for-mysql84-8.4.0_8.3.0-1.el9`
- the `rpm -qi` _description_ will show all the build options used
- While the build time will be quite short as we only build the plugin nothing else.
- however this needs to download the version of MySQL/Percona-Server from their respective git trees.

A typical usage would be:

- `build_one centos9 mysql-8.0.37 Percona-Server-8.0.36-28 1.77.0`, or
- `build_one ol9 mysql-8.4.0 Percona-Server-8.3.0-1`

## Notes

- Percona builds typically are available some time after they have merged changes in from upstream, so you may want to build against a new version of MySQL using the previous version of the PAM plugin from Percona.
- plugin compatibility is generally stable but did change in 8.0.
- The LICENSE for building is BSD 2-clause while the upstream source code is
GPL. The upstream source is not included in this repo.

- Patches are welcome. Please file a Pull Request
- If you see any problems with the code please file an Issue.
