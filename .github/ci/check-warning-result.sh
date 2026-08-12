#!/bin/sh
# Report the recorded -Wall -Werror result. Warning jobs use job-level
# continue-on-error, so a non-zero exit remains visible without blocking CI.
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <platform-slug>" >&2
    exit 2
fi

slug=$1
out=".ci-warning-output/$slug"
status="$out/exit-code"

if [ ! -f "$status" ]; then
    echo "::warning title=Compiler warning build unavailable::$slug did not produce a warning-build result (VM/setup may have failed)"
    exit 1
fi

rc=$(cat "$status")
case "$rc" in
    ''|*[!0-9]*)
        echo "::warning title=Compiler warning build invalid::$slug produced invalid exit status '$rc'"
        exit 1
        ;;
esac

if [ "$rc" -eq 0 ]; then
    echo "-Wall -Werror build passed on $slug"
    exit 0
fi

echo "::warning title=-Wall -Werror build failed::$slug failed the advisory compiler-warning build (exit $rc); functional CI is unaffected"
for log in deps.log warnings.log config.warnings.log; do
    if [ -f "$out/$log" ]; then
        echo "===== tail: $log ====="
        tail -n 80 "$out/$log" || true
    fi
done
exit "$rc"
