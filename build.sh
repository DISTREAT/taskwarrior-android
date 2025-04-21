#!/bin/sh
set -o errexit
set -o nounset

app_name="taskwarrior-android-buildenv"

build_image() {
    docker build \
        --tag "${app_name}" \
        .
}

run_container() {
    docker run \
        --rm \
        --volume "${PWD}/taskwarrior:/build" \
        --interactive \
        --tty \
        "${app_name}"
}

main() {
    build_image
    run_container
}

main
