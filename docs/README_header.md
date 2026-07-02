# HCP TerraformAgent on AWS



## What this demo demonstrates



## Features



## Demo Components



## How this demo works



## Demo Value Proposition



## How to Conduct the Demo



## Expected Behavior



## Permissions

### AWS Provider Permissions



### Terraform Provider Permissions



## Authentications

### AWS Provider Authentication

To provision resources on AWS, Terraform requires authentication. You can authenticate using any of the standard methods supported by the AWS Provider.

* **OIDC via HCP Terraform (Recommended)**: For VCS-driven workflows, configure HCP Terraform to use Dynamic Provider Credentials to assume an AWS IAM role.
* **Environment Variables**: Export standard AWS credentials for local debugging.

  ```bash
  export AWS_ACCESS_KEY_ID="anaccesskey"
  export AWS_SECRET_ACCESS_KEY="asecretkey"
  export AWS_SESSION_TOKEN="asessiontoken" # optional
  export AWS_REGION="ca-central-1"
  ```

* **Shared Credentials File**: Use an AWS profile defined in `~/.aws/credentials`.

### Terraform Provider Authentication


