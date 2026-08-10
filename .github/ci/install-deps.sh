#!/bin/sh
# Install only the packages needed to build and test the release tarball.  The
# tarball already contains generated configure/doc files, so autotools/docbook
# tools are intentionally not installed on every test guest.
set -eu

as_root()
{
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v pfexec >/dev/null 2>&1; then
        pfexec "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    elif command -v doas >/dev/null 2>&1; then
        doas "$@"
    else
        echo "Need root privileges to install build dependencies: $*" >&2
        return 1
    fi
}

check_test_perl()
{
    # Test::More's minimum version must be expressed as a Perl use
    # VERSION statement.  -MTest::More=0.90 would instead pass 0.90
    # to Test::More::import(), which exits 255.
    perl -e 'use Getopt::Long; use Test::More 0.90; use Data::Dumper; use IPC::Cmd;'
}

os=$(uname -s)
case "$os" in
    Linux)
        if [ ! -r /etc/os-release ]; then
            echo "Linux guest has no /etc/os-release" >&2
            exit 1
        fi
        # shellcheck disable=SC1091
        . /etc/os-release
        id=${ID:-unknown}
        like=${ID_LIKE:-}
        case "$id" in
            ubuntu|debian)
                as_root apt-get update
                as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
                    build-essential pkg-config libncurses-dev gzip tar perl
                ;;
            fedora|almalinux|rocky|ol|oraclelinux|centos)
                as_root dnf -y install \
                    gcc make pkgconf-pkg-config ncurses-devel gzip tar \
                    perl perl-Test-Simple perl-IPC-Cmd perl-Test-Harness
                ;;
            opensuse-leap|opensuse-tumbleweed|sles)
                as_root zypper --non-interactive refresh
                as_root zypper --non-interactive install \
                    gcc make pkg-config ncurses-devel gzip tar perl
                ;;
            alpine)
                as_root apk add --no-cache \
                    build-base pkgconf ncurses-dev linux-headers gzip tar \
                    perl perl-test-simple
                ;;
            arch|archlinux)
                as_root pacman -Syu --noconfirm --needed \
                    base-devel pkgconf ncurses gzip tar perl
                ;;
            *)
                case "$like" in
                    *debian*)
                        as_root apt-get update
                        as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
                            build-essential pkg-config libncurses-dev gzip tar perl
                        ;;
                    *rhel*|*fedora*)
                        as_root dnf -y install \
                            gcc make pkgconf-pkg-config ncurses-devel gzip tar \
                            perl perl-Test-Simple perl-IPC-Cmd perl-Test-Harness
                        ;;
                    *)
                        echo "Unsupported Linux distribution: ID=$id ID_LIKE=$like" >&2
                        exit 1
                        ;;
                esac
                ;;
        esac
        check_test_perl
        ;;
    SunOS)
        # OmniOS provides the normal developer toolchain as build-essential.
        # Avoid invoking pkg when both packages are already installed: IPS can
        # use a non-zero informational status for a no-change operation.
        if ! pkg list build-essential system/header >/dev/null 2>&1; then
            as_root pkg install -v build-essential system/header
        fi
        if command -v perl >/dev/null 2>&1; then
            check_test_perl
        fi
        ;;
    FreeBSD)
        if ! command -v perl >/dev/null 2>&1; then
            as_root pkg install -y perl5
        fi
        check_test_perl
        ;;
    DragonFly)
        if ! command -v perl >/dev/null 2>&1; then
            as_root pkg install -y perl5
        fi
        check_test_perl
        ;;
    NetBSD)
        if ! command -v perl >/dev/null 2>&1; then
            if command -v pkgin >/dev/null 2>&1; then
                as_root pkgin -y install perl
            elif command -v pkg_add >/dev/null 2>&1; then
                as_root pkg_add perl
            else
                echo "NetBSD guest has neither perl nor a supported package installer" >&2
                exit 1
            fi
        fi
        check_test_perl
        ;;
    OpenBSD|Darwin)
        # These images already contain a compiler, make, curses and a suitable
        # Perl environment for this release-tarball build.
        check_test_perl
        ;;
    *)
        echo "No dependency recipe for $os" >&2
        exit 1
        ;;
esac
