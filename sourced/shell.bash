#!/usr/bin/env bash

### General-purpose scripts to be sourced into other scripts.

bold() {
  local text="${1}"

  local bold_font_code
  bold_font_code="$(tput 'bold')"
  local regular_font_code
  regular_font_code="$(tput 'sgr0')"

  printf '%s%s%s' "${bold_font_code}" "${text}" "${regular_font_code}"
}

generate_random_string() {
  local length="${1:-16}"

  # https://unix.stackexchange.com/a/230676/408406
  head /dev/urandom | tr -dc A-Za-z0-9 | head -c "${length}"
}

format_url() {
  # TODO: rename to bold_url
  local url="${1}"

  printf '%s' "$(bold "${url}")"
}
