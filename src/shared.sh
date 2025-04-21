#!/bin/sh
check_env_var() {
    [ -n "${1}" ] || {
        echo "fail-fast: undefined variable: ${2}" >&2
        exit 1
    }
}
