# Shell Scripts

A collection of shell (POSIX, Bash) scripts for various purposes.

## Google Cloud Platform Scripts

### Service Account Creation

1. Download:
    ```shell
    curl \
        --silent \
        --output ./create_gcp_service_account \
        https://raw.githubusercontent.com/webyneter/shell-scripts/master/gcp/create_gcp_service_account.bash
    chmod +x ./create_gcp_service_account
    ```
1. Run:
    ```shell
    ./create_gcp_service_account \
      my-project \
      my-service-account-username \
      'My Service Account description' \
      .gcp_service_account_private_keys
    ```

### Service Account IAM Role Binding

1. Download:
    ```shell
    curl \
        --silent \
        --output ./assign_gcp_service_account_iam_roles \
        https://raw.githubusercontent.com/webyneter/shell-scripts/master/gcp/assign_gcp_service_account_iam_roles.bash
    chmod +x ./assign_gcp_service_account_iam_roles
    ```
1. Run:
    ```shell
    ./assign_gcp_service_account_iam_roles \
      my-project \
      my-service-account-username \
      'roles/serviceusage.serviceUsageAdmin roles/servicemanagement.admin roles/compute.networkAdmin'
    ```
