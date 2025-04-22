# AWS ECS with Datadog Integration using Terraform

This project provides a Terraform configuration to launch an AWS Elastic Container Service (ECS) cluster running an Nginx application, integrated with Datadog for monitoring and Cloud Workload Security (CWS). It leverages AWS Fargate for serverless container execution and includes an Application Load Balancer (ALB) to handle traffic. Logs are sent to AWS CloudWatch and can be further integrated with Datadog.

## 📂 Project Structure
├── .github/workflows/deploy.yaml  # GitHub Actions workflow for CI/CD
├── .gitignore                     # Specifies intentionally untracked files for Git
├── ecs.tf                         # Defines ECS cluster, task definition, and service
├── iam.tf                         # Defines IAM roles and policies for ECS tasks
├── loadbalancer.tf                # Defines ALB, target group, and listener
├── main.tf                        # Configures Terraform backend and required providers
├── network.tf                     # Defines VPC, subnets, and security groups
├── outputs.tf                     # Defines output values of deployed resources
├── README.md                      # This file (Project documentation)
├── variables.tf                   # Defines input variables for Terraform configuration

## ✅ Prerequisites

Before deploying, ensure you have:

* **AWS Account:** An active AWS account.
* **AWS CLI:** Installed and configured with necessary permissions.
* **Terraform:** Version `1.7.x` or compatible.
* **Git:** Installed for repository management.
* **GitHub Repository:** Project hosted on GitHub for workflow usage.
* **Datadog Account & API Key:** For Datadog Agent integration.
* **S3 Bucket for Terraform State:** Created in AWS (`us-east-1` configured).

## ⚙️ Setup and Configuration

1.  **Clone Repository:**
    ```bash
    git clone <repository_url>
    cd <repository_name>
    ```

2.  **Configure Terraform Backend (`main.tf`):**
    Update with your S3 bucket details:
    ```terraform
    terraform {
      backend "s3" {
        bucket = "your-terraform-state-bucket-name"
        key    = "terraform.tfstate"
        region = "us-east-1" # Adjust if your bucket is in a different region
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
    Replace placeholder with your Datadog API key:
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

4.  **Configure AWS Region (GitHub Workflow - `.github/workflows/deploy.yaml`):**
    Set your desired AWS region:
    ```yaml
    env:
      AWS_REGION: "sa-east-1" # Replace with your AWS region (e.g., sa-east-1 for Brazil)
      // ... other environment variables ...
    ```

5.  **Configure GitHub Secrets:**
    In your GitHub repository settings, add the following secrets:
    * `AWS_ACCESS_KEY_ID`
    * `AWS_SECRET_ACCESS_KEY`
    * `TF_STATE_BUCKET` (Your S3 bucket name)

## 🚀 Deployment

Choose your preferred deployment method:

### ☁️ Using GitHub Actions (CI/CD)

1.  **Commit & Push:** Push your changes to the `main` branch. This triggers the workflow.
2.  **Monitor:** Check the "Actions" tab for workflow progress. It will handle initialization, formatting, validation, planning (on PRs), and applying (on `main` branch pushes).

### 🛠️ Running Terraform Locally (Manual)

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    ```bash
    terraform plan
    ```
3.  **Apply Changes:**
    ```bash
    terraform apply -auto-approve
    ```

## ⚙️ Architecture

This project deploys:

* **VPC & Subnets (`network.tf`):** VPC with public subnets across AZs.
* **Security Groups (`network.tf`, `loadbalancer.tf`):** For ECS tasks and ALB traffic control.
* **IAM Roles & Policies (`iam.tf`):** Permissions for ECS tasks and agent.
* **ECS Cluster (`ecs.tf`):** Logical grouping for containers.
* **ECS Task Definition (`ecs.tf`):** Container configuration (Nginx, Datadog Agent). Includes Docker images, resources, ports, logging (CloudWatch), and Datadog setup.
* **ECS Service (`ecs.tf`):** Manages Nginx task instances (default: 2) on Fargate.
* **CloudWatch Log Group (`ecs.tf`):** Collects logs from ECS tasks.
* **Application Load Balancer (ALB) (`loadbalancer.tf`):** Distributes HTTP traffic to ECS tasks.
* **ALB Target Group (`loadbalancer.tf`):** Defines ECS tasks as traffic targets.
* **ALB Listener (`loadbalancer.tf`):** Listens on port 80 and forwards traffic.

## 📊 Datadog Integration

The Datadog Agent runs as a sidecar in ECS tasks, configured to:

* Collect infrastructure metrics.
* Enable Cloud Workload Security (CWS).
* Configuration via environment variables (including API key).

Nginx container logs are sent to AWS CloudWatch. To forward these to Datadog, configure the Datadog AWS integration in your Datadog account to collect from the `/ecs/my-app-service/` CloudWatch Log Group.

## 📤 Outputs

The `outputs.tf` file provides access to key deployed resources, like the ALB DNS name.

## 🤝 Contributing

Feel free to contribute by submitting pull requests or opening issues for improvements or bug fixes.

## 📜 License

This project is under the MIT License. See the `LICENSE` file for details.