#!/usr/bin/env bash
#
# tty utilities for zero.sh.
set -o errexit -o nounset

set +o nounset
# Respect https://no-color.org/ and https://bixense.com/clicolors/.
if [ -n "$NO_COLOR" ] ||
    [[ -n $CLICOLOR && $CLICOLOR -eq 0 ]] ||
    [[ ! -t 1 && $CLICOLOR_FORCE -eq 0 ]]; then
    UNDERLINE=""
    BOLD=""

    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""

    RESET=""
else
    UNDERLINE="$(tput smul)"
    BOLD="$(tput bold)"

    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"

    RESET="$(tput sgr0)"
fi
set -o nounset

puts() {
    local -r msg="$1"
    echo -e "${UNDERLINE}${GREEN}Success!${RESET} $msg"
}

putprogress() {
    local -r msg="$1"
    echo -e "${BOLD}${BLUE}==>${RESET} ${BOLD}$msg${RESET}"
}

puterr() {
    local -r msg="$1"
    echo >&2 -e "${RED}Error${RESET}: $msg"
}

putbold() {
    local -r msg="$1"
    echo -e "${BOLD}${YELLOW}$msg${RESET}"
}

print_run_cmd() {
    printf "${BOLD}${YELLOW}==>${RESET} %s${RESET}\n" "$*"
    "$@"
}

tty::pause() {
    local character
    read -rp "$1" -n1 character
    echo "$character"
}
