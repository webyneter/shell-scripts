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

### Create or update a Terraform Cloud (TFC) workspace.
### https://www.terraform.io/docs/cloud/api/workspaces.html
###
### Required environment variables:
###   TERRAFORM_VERSION: the version of Terraform that the workspace will use.
###   TFC_TOKEN: the TFC API token with workspace creation privileges, see https://www.terraform.io/docs/cloud/users-teams-organizations/api-tokens.html.
###   TFC_ORGANIZATION_NAME: the name of the TFC organization.
###   TFC_WORKSPACE_*: https://www.terraform.io/docs/cloud/api/workspaces.html#request-body

set -o errexit
set -o nounset
set -o noclobber

# shellcheck disable=SC1090
source <(curl --silent https://raw.githubusercontent.com/webyneter/shell-scripts/master/sourced/shell.bash)
# shellcheck disable=SC1090
source <(curl --silent https://raw.githubusercontent.com/webyneter/shell-scripts/master/sourced/tfc.bash)

create_or_update_workspace \
  "${TERRAFORM_VERSION}" \
  "${TFC_TOKEN}" \
  "${TFC_ORGANIZATION_NAME}" \
  "${TFC_WORKSPACE_NAME}" \
  "${TFC_WORKSPACE_ALLOW_DESTROY_PLAN:-false}" \
  "${TFC_WORKSPACE_AUTO_APPLY:-false}" \
  "${TFC_WORKSPACE_DESCRIPTION}" \
  "${TFC_WORKSPACE_FILE_TRIGGERS_ENABLED:-true}" \
  "${TFC_WORKSPACE_GLOBAL_REMOTE_STATE:-false}" \
  "${TFC_WORKSPACE_QUEUE_ALL_RUNS:-false}" \
  "${TFC_WORKSPACE_SPECULATIVE_ENABLED:-true}" \
  "${TFC_WORKSPACE_SOURCE_BASE_URL}" \
  "${TFC_WORKSPACE_VCS_REPO_IDENTIFIER}" \
  "${TFC_WORKSPACE_VCS_REPO_OAUTH_TOKEN_ID}" \
  "${TFC_WORKSPACE_VCS_REPO_BRANCH}" \
  "${TFC_WORKSPACE_WORKING_DIRECTORY}"
