#!/usr/bin/env bash

function progress_bar() {
    current=$1
    total=$2

    progress=$((current * 100 / total))
    bar="$(yes '#' | head -n ${progress} | tr -d '\n')"

    printf "\r[%-100s] (%d%%)" "${bar}" "${progress}" >&2
}

function finish_progress_bar() {
    progress_bar "100" "100"
    sleep 0.5
    echo -ne '\r\033[K'
}
