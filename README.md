```markdown
# AWS ECS with Datadog Integration using Terraform

This project provides a Terraform configuration to launch an AWS Elastic Container Service (ECS) cluster running an Nginx application, integrated with Datadog for monitoring and Cloud Workload Security (CWS). The project leverages AWS Fargate for serverless container execution and includes an Application Load Balancer (ALB) to handle traffic. Logs are sent to AWS CloudWatch and can be further integrated with Datadog.

## Project Structure

The project is structured as follows:

```
.
├── .github/workflows/deploy.yaml  # GitHub Actions workflow for CI/CD
├── .gitignore                     # Specifies intentionally untracked files that Git should ignore
├── ecs.tf                         # Defines the ECS cluster, task definition, and service
├── iam.tf                         # Defines IAM roles and policies for ECS tasks
├── loadbalancer.tf                # Defines the Application Load Balancer, target group, and listener
├── main.tf                        # Configures the Terraform backend and required providers
├── network.tf                     # Defines the VPC, subnets, and security groups
├── outputs.tf                     # Defines output values for easy access to deployed resources
├── README.md                      # This file
├── variables.tf                   # Defines input variables for the Terraform configuration
```

## Prerequisites

Before you can deploy this infrastructure, you need to have the following:

* **AWS Account:** You need an active AWS account.
* **AWS CLI:** The AWS Command Line Interface should be installed and configured with credentials that have the necessary permissions to create AWS resources (e.g., `AdministratorAccess` for initial setup, but it's recommended to use more granular permissions for production).
* **Terraform:** Terraform version `1.7.x` (as specified in the GitHub Actions workflow) or a compatible version should be installed on your local machine if you plan to run Terraform commands locally.
* **Git:** Git should be installed to manage the project repository and for GitHub Actions to function.
* **GitHub Repository:** The Terraform configuration should be in a GitHub repository to utilize the provided workflow.
* **Datadog Account and API Key:** You need a Datadog account and a Datadog API key to enable the Datadog Agent in the ECS tasks.
* **S3 Bucket for Terraform State:** An S3 bucket should be created in your AWS account (e.g., in `us-east-1` as configured) to store the Terraform state file. The bucket name should be updated in `main.tf`.

## Setup and Configuration

Follow these steps to set up and configure the project:

1.  **Clone the Repository:** Clone this repository to your local machine.
    ```bash
    git clone <repository_url>
    cd <repository_name>
    ```

2.  **Configure Terraform Backend (`main.tf`):**
    Update the `backend "s3"` block in `main.tf` with the name of your S3 bucket and the desired region (if it's different from `us-east-1`).
    ```terraform
    terraform {
      backend "s3" {
        bucket = "your-terraform-state-bucket-name" # Replace with your bucket name
        key    = "terraform.tfstate"
        region = "us-east-1"                     # Replace if your bucket is in a different region
      }
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
      }
    }
    ```

3.  **Configure Datadog API Key (`ecs.tf`):**
    In the `ecs.tf` file, locate the `datadog-agent` container definition and replace `<YOUR_DD_API_KEY>` with your actual Datadog API key. For production environments, consider using AWS Secrets Manager or SSM Parameter Store to manage this sensitive information.
    ```terraform
    {
      name      = "datadog-agent",
      image     = "datadog/agent:latest",
      essential = true,
      environment = [
        {
          name  = "DD_API_KEY",
          value = "<YOUR_DD_API_KEY>" # Replace with your Datadog API key
        },
        // ... other Datadog environment variables ...
      ],
      // ... other Datadog agent configuration ...
    }
    ```

4.  **Configure AWS Region (`.github/workflows/deploy.yaml`):**
    In the `.github/workflows/deploy.yaml` file, ensure the `AWS_REGION` environment variable is set to the AWS region where you intend to deploy your infrastructure (e.g., `sa-east-1` for Brazil).
    ```yaml
    env:
      AWS_REGION: "sa-east-1" # Replace with your AWS region
      // ... other environment variables ...
    ```

5.  **Configure AWS Credentials in GitHub Secrets:**
    Set up the following secrets in your GitHub repository under "Settings" -> "Secrets and variables" -> "Actions secrets":
    * `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
    * `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.
    * `TF_STATE_BUCKET`: The name of your S3 bucket for Terraform state (should match the one in `main.tf`).

## Deployment

You can deploy this infrastructure using either GitHub Actions (for CI/CD) or by running Terraform commands locally.

### Using GitHub Actions (Recommended)

1.  **Commit and Push Changes:** Commit all your configuration changes to the `main` branch of your GitHub repository. This will automatically trigger the GitHub Actions workflow defined in `.github/workflows/deploy.yaml`.
2.  **Monitor Workflow:** Go to the "Actions" tab in your GitHub repository to monitor the progress of the workflow. The workflow will:
    * Initialize Terraform.
    * Format and validate the Terraform configuration.
    * Plan the changes (on pull requests).
    * Apply the changes (on pushes to the `main` branch).

### Running Terraform Locally (For Testing or Manual Deployment)

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan the Changes:**
    ```bash
    terraform plan
    ```
3.  **Apply the Changes:**
    ```bash
    terraform apply -auto-approve
    ```

## Architecture Overview

This project deploys the following AWS resources:

* **VPC and Subnets (`network.tf`):** A new Virtual Private Cloud (VPC) with public subnets across multiple Availability Zones for high availability.
* **Security Groups (`network.tf`, `loadbalancer.tf`):** Security groups to control inbound and outbound traffic for the ECS tasks and the Application Load Balancer.
* **IAM Roles and Policies (`iam.tf`):** IAM roles with the necessary permissions for the ECS tasks to access other AWS services and for the ECS agent to manage resources on your behalf.
* **ECS Cluster (`ecs.tf`):** A logical grouping for your containerized applications.
* **ECS Task Definition (`ecs.tf`):** A blueprint for your Nginx container and the Datadog Agent, specifying the Docker images, resource requirements, port mappings, logging configuration (to CloudWatch), and Datadog integration.
* **ECS Service (`ecs.tf`):** Runs and maintains a specified number of instances (default: 2) of your Nginx task definition within the ECS cluster on AWS Fargate.
* **CloudWatch Log Group (`ecs.tf`):** A dedicated CloudWatch Log Group to collect logs from the ECS tasks.
* **Application Load Balancer (ALB) (`loadbalancer.tf`):** Distributes incoming HTTP traffic to the ECS tasks.
* **ALB Target Group (`loadbalancer.tf`):** Defines the targets (ECS tasks) that the ALB routes traffic to.
* **ALB Listener (`loadbalancer.tf`):** Checks for incoming connections on port 80 and forwards them to the target group.

## Datadog Integration

The ECS tasks include the Datadog Agent as a sidecar container. This agent is configured to:

* Collect infrastructure metrics from the Fargate tasks.
* Potentially enable Cloud Workload Security (CWS) for runtime security monitoring.
* The agent is configured using environment variables, including your Datadog API key.

Logs from the Nginx container are sent to AWS CloudWatch using the `awslogs` log driver. To send these logs to Datadog, you need to configure the Datadog AWS integration in your Datadog account to collect logs from the specified CloudWatch Log Group (`/ecs/my-app-service/`).

## Outputs

The `outputs.tf` file defines values that are printed after a successful deployment, such as the DNS name of the Application Load Balancer, which you can use to access your Nginx application.

## Contributing

Contributions to this project are welcome. Please feel free to submit pull requests or open issues for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more information.
```