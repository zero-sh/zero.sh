#!/bin/sh
#
# tty utilities for zero.sh.
set -o errexit -o nounset

# Respect https://no-color.org/.
if [ -n "${NO_COLOR:-}" ]; then
    BOLD=""

    YELLOW=""
    BLUE=""

    RESET=""
else
    BOLD="$(tput bold)"

    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"

    RESET="$(tput sgr0)"
fi

putprogress() {
    printf "${BOLD}${BLUE}==>${RESET} ${BOLD}%s${RESET}\n" "$1"
}

print_run_cmd() {
    printf "${BOLD}${YELLOW}==>${RESET} %s${RESET}\n" "$*"
    "$@"
}
