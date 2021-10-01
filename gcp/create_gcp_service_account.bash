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
###   1:   the username prefix of the Service Account.
###   2:   the ID of the Project where the Service Account is to be created.
###   [3]: the full path of the directory where the created Service Account's private JSON key is to be downloaded to;
###        defaults to .gcp_service_account_private_keys/

set -o errexit
set -o nounset
set -o noclobber

username_prefix="${1}"
project_id="${2}"
service_account_private_key_dir_path="${3:-.gcp_service_account_private_keys}"

# Why the random suffix:
# https://cloud.google.com/iam/docs/understanding-service-accounts#deleting_and_recreating_service_accounts
random_hex="$(openssl rand -hex 4)"
service_account_name="${username_prefix}-${random_hex}"

printf "A %s Service Account is about to be created in the %s project, 'Y' or 'y' to confirm: " "${service_account_name}" "${project_id}"
read prompt_reply
if [ "${prompt_reply}" = "${prompt_reply#[Yy]}" ]; then
  printf 'Exited without creating a Service Account.'
  exit 0
fi

printf 'Creating a %s Service Account in the %s project...' "${service_account_name}" "${project_id}"
gcloud \
  --project="${project_id}" \
  iam service-accounts create "${service_account_name}" \
  --description="For use by Terraform" \
  --display-name="${service_account_name}"

printf "Creating a private key for the %s, and downloading it..." "${service_account_name}"
gcloud \
  --project="${project_id}" \
  iam service-accounts keys create "${service_account_private_key_dir_path}/${service_account_email}.json" \
  --iam-account="${service_account_email}"
