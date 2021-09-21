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

### Terraform Cloud API scripts to be sourced into other scripts.
### https://www.terraform.io/docs/cloud/api/index.html

api_version='v2'

create_or_update_workspace() {
  local version="${1}"
  local token="${2}"
  local organization_name="${3}"
  local workspace_name="${4}"
  local workspace_allow_destroy_plan="${5}"
  local workspace_auto_apply="${6}"
  local workspace_description="${7}"
  local workspace_file_triggers_enabled="${8}"
  local workspace_global_remote_state="${9}"
  local workspace_queue_all_runs="${10}"
  local workspace_speculative_enabled="${11}"
  local workspace_source_base_url="${12}"
  local workspace_vsc_repo_identifier="${13}"
  local workspace_vsc_repo_oauth_token_id="${14}"
  local workspace_vcs_repo_branch="${15}"
  local workspace_working_directory="${16}"

  workspace_payload="
  {
    \"data\": {
      \"attributes\": {
        \"type\": \"workspaces\",
        \"name\": \"${workspace_name}\",
        \"allow-destroy-plan\": ${workspace_allow_destroy_plan},
        \"auto-apply\": ${workspace_auto_apply},
        \"description\": \"${workspace_description}\",
        \"execution-mode\": \"remote\",
        \"file-triggers-enabled\": ${workspace_file_triggers_enabled},
        \"global-remote-state\": ${workspace_global_remote_state},
        \"queue-all-runs\": ${workspace_queue_all_runs},
        \"source-name\": \"$(whoami) at $(hostname) via ${0}\",
        \"source-url\": \"${workspace_source_base_url}/${workspace_vsc_repo_identifier}\",
        \"speculative-enabled\": ${workspace_speculative_enabled},
        \"terraform-version\": \"${version}\",
        \"vcs-repo\": {
          \"identifier\": \"${workspace_vsc_repo_identifier}\",
          \"oauth-token-id\": \"${workspace_vsc_repo_oauth_token_id}\",
          \"branch\": \"${workspace_vcs_repo_branch}\"
        },
        \"working-directory\": \"${workspace_working_directory}\"
      }
    }
  }
  "

  workspace_url="https://app.terraform.io/app/${organization_name}/workspaces/${workspace_name}"
  formatted_workspace_url="$(format_url "${workspace_url}")"

  # https://www.terraform.io/docs/cloud/api/workspaces.html#create-a-workspace
  create_workspace_http_code="$(
    curl \
      --header "Authorization: Bearer ${token}" \
      --header "Content-Type: application/vnd.api+json" \
      --request 'POST' \
      --data "${workspace_payload}" \
      --write-out '%{http_code}' \
      --silent \
      --output /dev/null \
      "https://app.terraform.io/api/${api_version}/organizations/${organization_name}/workspaces"
  )"
  workspace_id=
  if [ "${create_workspace_http_code}" = '422' ]; then
    # The workspace already exists--update it instead.
    workspace_id="$(
      curl \
        --header "Authorization: Bearer ${token}" \
        --header "Content-Type: application/vnd.api+json" \
        --request 'PATCH' \
        --data "${workspace_payload}" \
        --silent \
        "https://app.terraform.io/api/${api_version}/organizations/${organization_name}/workspaces/${workspace_name}" |
        jq -r '.data.id'
    )"
    printf 'The %s workspace has successfully been updated.\n' "${workspace_name}"
  else
    workspace_id="$(
      curl \
        --header "Authorization: Bearer ${token}" \
        --header "Content-Type: application/vnd.api+json" \
        --silent \
        "https://app.terraform.io/api/${api_version}/organizations/${organization_name}/workspaces/${workspace_name}" |
        jq -r '.data.id'
    )"

    printf 'The %s workspace has successfully been created in the %s organization:\n%s\n' \
      "${workspace_name}" \
      "${organization_name}" \
      "${formatted_workspace_url}"

    if [ "${workspace_queue_all_runs}" = 'false' ]; then
      printf 'The %s workspace has been created with data.attributes.queue-all-runs set to false so you will need to start a first Run manually before VCS-driven Runs can be automatically initiated later on. To do that, navigate the workspace:\n%s\nand press %s -> %s in the top right corner.\n' \
        "${workspace_name}" \
        "${formatted_workspace_url}" \
        "$(bold 'Actions')" \
        "$(bold 'Start new plan')"
    fi
  fi
  printf '\n'

  printf 'Make sure all the necessary Terraform Variables and Environment Variables are set in the %s workspace.\n' \
    "${workspace_name}"
  printf '\n'
}

construct_runs_url() {
  local organization_name="${1}"
  local workspace_name="${2}"

  printf 'https://app.terraform.io/app/%s/workspaces/%s/runs' "${organization_name}" "${workspace_name}"
}

construct_run_url() {
  local organization_name="${1}"
  local workspace_name="${2}"
  local run_id="${3}"

  printf '%s/%s' "$(construct_runs_url "${organization_name}" "${workspace_name}")" "${run_id}"
}

find_run_id_by_message_prefix() {
  local token="${1}"
  local organization_name="${2}"
  local workspace_id="${3}"
  local workspace_name="${4}"
  local message_prefix="${5}"

  local sleep_for
  sleep_for=5
  while
    :
    local page_number
    page_number=1
    local page_size
    page_size=10

    # https://www.terraform.io/docs/cloud/api/run.html#list-runs-in-a-workspace
    local workspace_list
    workspace_list="$(
      curl \
        --header "Authorization: Bearer ${token}" \
        --request 'GET' \
        --silent \
        "https://app.terraform.io/api/${api_version}/workspaces/${workspace_id}/runs?page[number]=${page_number}&page[size]=${page_size}"
    )"
    local run_id
    run_id="$(
      printf '%s' "${workspace_list}" |
        jq -r ".data[] | select(.attributes.message | contains(\"${message_prefix}\") ) | .id"
    )"
    if [ -n "${run_id}" ]; then
      run_url="$(construct_run_url "${organization_name}" "${workspace_name}" "${run_id}")"
      printf 'The Terraform Cloud Run with the message containing the %s prefix has been found: \n%s\n' "${message_prefix}" "$(format_url "${run_url}")"
      break
    fi

    printf 'Waiting for the Terraform Cloud Run to pop up for another %s seconds...\n' "${sleep_for}"
    sleep "${sleep_for}"
  do :; done

  # shellcheck disable=SC2034
  find_tfc_run_id_by_message_prefix_result="${run_id}"
}

get_workspace_name() {
  local token="${1}"
  local workspace_id="${2}"

  # https://www.terraform.io/docs/cloud/api/workspaces.html#show-workspace
  workspace_name=$(
    curl \
      --header "Authorization: Bearer ${token}" \
      --header 'Content-Type: application/vnd.api+json' \
      --request 'GET' \
      --silent \
      "https://app.terraform.io/api/${api_version}/workspaces/${workspace_id}" |
      jq -r '.data.attributes."name"'
  )

  printf '%s' "${workspace_name}"
}

_keep_checking_up_on_run() {
  local token="${1}"
  local run_id="${2}"
  local runs_url="${3}"
  local sleep_while_waiting="${4:-5}"

  local status
  local seconds_since_last_pending_status=0
  local max_seconds_since_last_pending_status=30
  while
    :
    # https://www.terraform.io/docs/cloud/api/run.html#get-run-details
    status=$(
      curl \
        --header "Authorization: Bearer ${token}" \
        --request 'GET' \
        --silent \
        "https://app.terraform.io/api/${api_version}/runs/${run_id}" |
        jq -r '.data.attributes."status"'
    )

    waiting_msg="will check up on it again in ${sleep_while_waiting} seconds..."
    # https://www.terraform.io/docs/cloud/api/run.html#run-states
    if [ "${status}" = 'pending' ]; then
      if [ "${seconds_since_last_pending_status}" -gt "${max_seconds_since_last_pending_status}" ]; then
        printf 'The Terraform Cloud Run has been in the pending state for a while now, you either have to wait a little longer before other Runs locking the workspace finish, or discard the Runs manually here:\n%s\n' "$(bold "${runs_url}")"
        seconds_since_last_pending_status=0
      fi
      printf 'The Terraform Cloud Run plan is about to be queued, %s\n' "${waiting_msg}"
      seconds_since_last_pending_status=$((seconds_since_last_pending_status + sleep_while_waiting))
    fi
    if [ "${status}" = 'plan_queued' ]; then
      printf 'The Terraform Cloud Run has been queued, %s\n' "${waiting_msg}"
    fi
    if [ "${status}" = 'planning' ]; then
      printf 'The Terraform Cloud Run is being planned, %s\n' "${waiting_msg}"
    fi
    if [ "${status}" = 'cost_estimating' ]; then
      printf 'The Terraform Cloud Run is being cost-estimated, %s\n' "${waiting_msg}"
    fi
    if [ "${status}" = 'policy_checking' ]; then
      printf 'The Terraform Cloud Run is being policy-checked, %s\n' "${waiting_msg}"
    fi
    if [ "${status}" = 'policy_override' ]; then
      printf 'The Terraform Cloud Run policy can be overridden.\n'
      break
    fi

    if [ "${status}" = 'planned_and_finished' ]; then
      printf 'The Terraform Cloud Run has been planned, and the plan does not need to be applied.\n'
      break
    fi

    if [ "${status}" = 'policy_checked' ] ||
      [ "${status}" = 'cost_estimated' ] ||
      [ "${status}" = 'planned' ]; then
      printf 'The Terraform Cloud Run has been %s, and is ready to be applied.\n' "${status}"
      break
    fi

    if [ "${status}" = 'apply_queued' ]; then
      printf 'The Terraform Cloud Run has been queued for application, %s\n' "${waiting_msg}"
    fi
    if [ "${status}" = 'applying' ]; then
      printf 'The Terraform Cloud Run is being applied, %s\n' "${waiting_msg}"
    fi
    if [ "${status}" = 'applied' ]; then
      printf 'The Terraform Cloud Run has been applied.\n'
      break
    fi

    if [ "${status}" = 'policy_soft_failed' ] ||
      [ "${status}" = 'discarded' ] ||
      [ "${status}" = 'errored' ] ||
      [ "${status}" = 'canceled' ] ||
      [ "${status}" = 'force_canceled' ]; then
      printf "ERROR: The Terraform Cloud Run has exited abruptly with the '%s' status.\n" "${status}"
      exit 1
    fi

    sleep "${sleep_while_waiting}"
  do :; done
  printf '\n'

  _keep_checking_up_on_tfc_run_result="${status}"
}

create_run() {
  local token="${1}"
  local organization_name="${2}"
  local workspace_id="${3}"

  workspace_name="$(get_workspace_name "${token}" "${workspace_id}")"
  printf "Creating a Terraform Cloud Run in the %s workspace..." "${workspace_name}"
  # https://www.terraform.io/docs/cloud/api/run.html#create-a-run
  run_payload="
{
  \"data\": {
    \"attributes\": {
      \"message\": \"Created by $(whoami) at $(hostname) via the Terraform Cloud API\"
    },
    \"type\":\"runs\",
    \"relationships\": {
      \"workspace\": {
        \"data\": {
          \"type\": \"workspaces\",
          \"id\": \"${workspace_id}\"
        }
      }
    }
  }
}
"
  run_id=$(
    curl \
      --header "Authorization: Bearer ${token}" \
      --header 'Content-Type: application/vnd.api+json' \
      --request 'POST' \
      --data "${run_payload}" \
      --silent \
      "https://app.terraform.io/api/${api_version}/runs" |
      jq -r '.data.id'
  )
  printf '\n'

  run_url="$(construct_run_url "${organization_name}" "${workspace_name}" "${run_id}")"
  printf 'The Terraform Cloud Run has been created, the URL is \n%s\n' "$(format_url "${run_url}")"
  printf '\n'

  # shellcheck disable=SC2034
  create_tfc_run_result="${run_id}"
}

apply_run() {
  local token="${1}"
  local organization_name="${2}"
  local workspace_id="${3}"
  local run_id="${4}"

  workspace_name="$(get_workspace_name "${token}" "${workspace_id}")"
  runs_url="$(construct_runs_url "${organization_name}" "${workspace_name}")"
  _keep_checking_up_on_run "${token}" "${run_id}" "${runs_url}"
  if [ "${_keep_checking_up_on_tfc_run_result}" = 'planned_and_finished' ]; then
    return
  fi

  printf "Applying the Terraform Cloud Run %s from the %s workspace..." "${run_id}" "${workspace_name}"
  # https://www.terraform.io/docs/cloud/api/run.html#apply-a-run
  queue_for_application_payload="
{
  \"comment\": \"Applied by $(whoami) at $(hostname) via the Terraform Cloud API.\"
}
"
  sleep_while_queueing_for_application_for_seconds=5
  timeout_seconds=$((60 * 5))
  looping_for_seconds=0
  while
    :
    if [ "${looping_for_seconds}" -gt "${timeout_seconds}" ]; then
      printf 'WARNING: The Terraform Cloud Run has exceeded the timeout of %s seconds, that might have been due to the Run failing or any other valid reason, check out the Run logs for more details.\n' "${timeout_seconds}"
      break
    fi

    http_code=$(
      curl \
        --header "Authorization: Bearer ${token}" \
        --header 'Content-Type: application/vnd.api+json' \
        --request 'POST' \
        --data "${queue_for_application_payload}" \
        --write-out '%{http_code}' \
        --silent \
        --output /dev/null \
        "https://app.terraform.io/api/${api_version}/runs/${run_id}/actions/apply"
    )

    if [ "${http_code}" = '202' ]; then
      break
    fi

    printf 'The Terraform Cloud Run is still being queued for application, waiting for another %s seconds before checking up on it again...\n' "${sleep_while_queueing_for_application_for_seconds}"
    looping_for_seconds=$((looping_for_seconds + sleep_while_queueing_for_application_for_seconds))
    sleep "${sleep_while_queueing_for_application_for_seconds}"
  do :; done
  printf '\n'

  _keep_checking_up_on_run "${token}" "${run_id}" "${runs_url}"
}
