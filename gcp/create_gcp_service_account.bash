#!/usr/bin/env sh

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

### Generate a Google Cloud Platform Service Account, and download its private JSON key.
### The caller must be authenticated against GCP.
###
### Required arguments:
###   1:   the ID of the Project where the Service Account is to be created.
###   2:   the username prefix of the Service Account.
###   3:   the description of the Service Account.
###   [4]: the full path of the directory where the created Service Account's private JSON key is to be downloaded to;
###        defaults to .gcp_service_account_private_keys/

set -o errexit
set -o nounset
set -o noclobber

project_id="${1}"
username_prefix="${2}"
description="${3}"
private_key_dir_path="${4:-.gcp_service_account_private_keys}"

# Why the random suffix:
# https://cloud.google.com/iam/docs/understanding-service-accounts#deleting_and_recreating_service_accounts
name="${username_prefix}-$(openssl rand -hex 4)"

printf "A %s Service Account is about to be created in the %s project, 'Y' or 'y' to confirm: " "${name}" "${project_id}"
read prompt_reply
if [ "${prompt_reply}" = "${prompt_reply#[Yy]}" ]; then
  printf 'Exited without creating a Service Account.\n'
  exit 0
fi

printf 'Creating a %s Service Account in the %s project...\n' "${name}" "${project_id}"
gcloud --project="${project_id}" iam service-accounts create "${name}" \
  --description="${description}" \
  --display-name="${name}"

printf 'Creating a private key for the %s, and downloading it...\n' "${name}"
email="${name}@${project_id}.iam.gserviceaccount.com"
gcloud --project="${project_id}" iam service-accounts keys create "${private_key_dir_path}/${email}.json" \
  --iam-account="${email}"
