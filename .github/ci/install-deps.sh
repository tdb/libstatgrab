#!/bin/sh
# Install only the packages needed to build the release tarball.  The tarball
# already contains generated configure/doc files, so autotools/docbook tools
# are intentionally not installed on every test guest.
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
                    build-essential pkg-config libncurses-dev gzip tar
                ;;
            fedora|almalinux|rocky|ol|oraclelinux|centos)
                as_root dnf -y install gcc make pkgconf-pkg-config ncurses-devel gzip tar
                ;;
            opensuse-leap|opensuse-tumbleweed|sles)
                as_root zypper --non-interactive refresh
                as_root zypper --non-interactive install gcc make pkg-config ncurses-devel gzip tar
                ;;
            alpine)
                as_root apk add --no-cache build-base pkgconf ncurses-dev gzip tar
                ;;
            arch|archlinux)
                as_root pacman -Syu --noconfirm --needed base-devel pkgconf ncurses gzip tar
                ;;
            *)
                case "$like" in
                    *debian*)
                        as_root apt-get update
                        as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
                            build-essential pkg-config libncurses-dev gzip tar
                        ;;
                    *rhel*|*fedora*)
                        as_root dnf -y install gcc make pkgconf-pkg-config ncurses-devel gzip tar
                        ;;
                    *)
                        echo "Unsupported Linux distribution: ID=$id ID_LIKE=$like" >&2
                        exit 1
                        ;;
                esac
                ;;
        esac
        ;;
    SunOS)
        # OmniOS has provided build-essential since r151026.  It pulls in the
        # current GCC and the normal development toolchain.
        as_root pkg install -v build-essential system/header
        ;;
    FreeBSD|OpenBSD|NetBSD|DragonFly|Darwin)
        # The BSD base systems and GitHub macOS images contain a C compiler,
        # make and curses sufficient for a release-tarball build.
        ;;
    *)
        echo "No dependency recipe for $os" >&2
        exit 1
        ;;
esac
