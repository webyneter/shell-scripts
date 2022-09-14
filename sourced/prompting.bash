#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2021 Nikita Shupeyko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

### Prompting scripts to be sourced into other scripts.

# shellcheck disable=SC1090
source <(curl --silent https://raw.githubusercontent.com/webyneter/shell-scripts/1.1.0/sourced/formatting.bash)

confirm_or_exit() {
  ### Request confirmation to proceed, or exit otherwise.
  ### Based upon https://stackoverflow.com/a/226724

  local message
  message=$(bold "${1}")
  message="${message} ('Y' or 'y' to confirm): "
  local non_confirmation_exit_code="${2:-0}"

  local reply
  while true; do
    read -p "${message}" reply
    case "${reply}" in
    [Yy]*)
      printf 'The confirmation has been given, proceeding...\n\n'
      break
      ;;
    *)
      printf 'No confirmation has been given, exiting...\n'
      exit "${non_confirmation_exit_code}"
      ;;
    esac
  done
}
