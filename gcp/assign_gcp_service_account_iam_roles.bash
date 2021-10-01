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

### Assign a Google Cloud Platform Service Account IAM roles.
### The caller must be authenticated against GCP.
###
### Required arguments:
###   1: the ID of the Project where the Service Account is to be created.
###   2: the username of the Service Account.
###   3: a quoted string of space-separated IAM roles.

set -o errexit
set -o nounset
set -o noclobber

project_id="${1}"
service_account_name="${2}"
iam_roles="${3}"

printf 'Assigning %s IAM roles...' "${service_account_name}"
service_account_email="${service_account_name}@${project_id}.iam.gserviceaccount.com"
set -- ${iam_roles}
for role; do
  printf "Assigning %s the %s IAM role..." "${service_account_name}" "${role}"
  gcloud \
    --project="${project_id}" \
    projects add-iam-policy-binding "${project_id}" \
    --member="serviceAccount:${service_account_email}" \
    --role="${role}"
done
