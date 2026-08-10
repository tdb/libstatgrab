#!/bin/sh
# Regression handling compatible with the old GitLab check-results jobs.
set -eu

usage()
{
    echo "usage:" >&2
    echo "  $0 normalize <downloaded-artifacts-dir> <normalized-dir>" >&2
    echo "  $0 compare   <normalized-current-dir> <reference-dir>" >&2
    echo "  $0 merge     <normalized-current-dir> <reference-dir> <publish-dir>" >&2
    exit 2
}

[ "$#" -ge 1 ] || usage
mode=$1
shift

case "$mode" in
    normalize)
        [ "$#" -eq 2 ] || usage
        src=$1
        dst=$2
        rm -rf "$dst"
        mkdir -p "$dst"
        count=0
        for artifact in "$src"/platform-*; do
            [ -d "$artifact" ] || continue
            name=$(basename "$artifact")
            if [ ! -f "$artifact/statgrab" ] || [ ! -f "$artifact/config.h" ]; then
                echo "::error title=Incomplete CI artifact::$name lacks statgrab and/or config.h"
                exit 1
            fi
            mkdir -p "$dst/$name"
            # Keep the historical normalization exactly: strip changing values,
            # omit filesystem instances, and retain only aggregate user fields.
            sed -e 's/ =.*$//' -e '/^fs.*:/d' "$artifact/statgrab" \
                | perl -ne 'unless($_=~/^user\./&&$_!~/^user\.names\s+/&&$_!~/^user\.num\s+/){print}' \
                | LC_ALL=C sort > "$dst/$name/statgrab.keys"
            cp "$artifact/config.h" "$dst/$name/config.h"
            if [ -f "$artifact/platform.txt" ]; then
                cp "$artifact/platform.txt" "$dst/$name/platform.txt"
            fi
            count=$((count + 1))
        done
        if [ "$count" -eq 0 ]; then
            echo "::error::No platform artifacts were downloaded"
            exit 1
        fi
        echo "Normalized $count platform artifacts"
        ;;

    compare)
        [ "$#" -eq 2 ] || usage
        current=$1
        reference=$2
        if [ ! -d "$reference" ] || ! ls "$reference"/platform-* >/dev/null 2>&1; then
            echo "::notice::No CI regression baseline exists yet; the first successful default-branch run will create it."
            exit 0
        fi
        changed=0
        for platform in "$current"/platform-*; do
            [ -d "$platform" ] || continue
            name=$(basename "$platform")
            ref="$reference/$name"
            if [ ! -d "$ref" ]; then
                echo "::notice title=New CI platform::$name has no previous baseline"
                continue
            fi
            for file in statgrab.keys config.h; do
                if ! cmp -s "$ref/$file" "$platform/$file"; then
                    echo "::error title=CI regression::$name changed $file"
                    diff -u "$ref/$file" "$platform/$file" || true
                    changed=1
                fi
            done
        done
        exit "$changed"
        ;;

    merge)
        [ "$#" -eq 3 ] || usage
        current=$1
        reference=$2
        publish=$3
        rm -rf "$publish"
        mkdir -p "$publish"
        if [ -d "$reference" ]; then
            cp -R "$reference"/. "$publish"/
        fi
        for platform in "$current"/platform-*; do
            [ -d "$platform" ] || continue
            name=$(basename "$platform")
            rm -rf "$publish/$name"
            cp -R "$platform" "$publish/$name"
        done
        ;;

    *)
        usage
        ;;
esac
