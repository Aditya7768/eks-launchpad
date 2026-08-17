# Terraform AWS EKS Cluster

This repository provisions an Amazon EKS (Elastic Kubernetes Service) cluster on AWS using Terraform, including the underlying VPC networking and managed node groups.

## Architecture

The configuration is split into two modules:

- **`modules/vpc`** — Creates a VPC with public and private subnets across multiple availability zones.
- **`modules/eks`** — Creates the EKS cluster and managed node groups inside the private subnets provisioned by the VPC module.

Terraform state is stored remotely in an S3 bucket, with state locking handled via a DynamoDB table.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- An AWS account with credentials configured (e.g. via `aws configure` or environment variables)
- An existing S3 bucket and DynamoDB table for remote state (see [Backend Configuration](#backend-configuration))
- `kubectl` (optional, for interacting with the cluster after it's created)

## Project Structure

```
.
├── main.tf         # Provider, backend, and module configuration
├── variable.tf     # Input variable definitions
├── output.tf       # Output values (cluster endpoint, name, VPC ID)
├── modules/
│   ├── vpc/        # VPC, subnets, and networking resources
│   └── eks/        # EKS cluster and node group resources
└── .gitignore
```

## Backend Configuration

This project uses an S3 backend for remote state storage:

| Setting          | Value                                |
|-------------------|---------------------------------------|
| Bucket            | `demo-terraform-eks-state-saad-bucket` |
| Key               | `terraform.tfstate`                   |
| Region            | `us-west-2`                           |
| DynamoDB table    | `terraform-eks-state-locks`           |
| Encryption        | Enabled                               |

Update the `backend "s3"` block in `main.tf` if you want to use your own bucket/table.

## Usage

1. **Initialize Terraform**

   ```bash
   terraform init
   ```

2. **Review the execution plan**

   ```bash
   terraform plan
   ```

3. **Apply the configuration**

   ```bash
   terraform apply
   ```

4. **Configure `kubectl` to access the new cluster**

   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster_name>
   ```

5. **Destroy the infrastructure** (when no longer needed)

   ```bash
   terraform destroy
   ```

## Input Variables

| Name                    | Description                          | Type     | Default                                              |
|--------------------------|---------------------------------------|----------|-------------------------------------------------------|
| `region`                 | AWS region                            | `string` | `us-west-2`                                           |
| `vpc_cidr`                | CIDR block for the VPC                | `string` | `10.0.0.0/16`                                          |
| `availability_zones`      | Availability zones to use             | `list(string)` | `["us-west-2a", "us-west-2b", "us-west-2c"]`     |
| `private_subnet_cidrs`    | CIDR blocks for private subnets       | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]`  |
| `public_subnet_cidrs`     | CIDR blocks for public subnets        | `list(string)` | `["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]`  |
| `cluster_name`            | Name of the EKS cluster               | `string` | `my-eks-cluster`                                      |
| `cluster_version`         | Kubernetes version for the cluster    | `string` | `1.30`                                                 |
| `node_groups`             | Map of EKS managed node group configs (instance types, capacity type, scaling config) | `map(object)` | See `variable.tf` — one `general` node group with `t3.medium` instances (min 1, desired 2, max 4) |

You can override any of these by creating a `terraform.tfvars` file or passing `-var` flags on the command line.

## Outputs

| Name                | Description            |
|----------------------|--------------------------|
| `cluster_endpoint`    | EKS cluster API endpoint |
| `cluster_name`        | Name of the EKS cluster  |
| `vpc_id`              | ID of the created VPC    |

## Notes

- The `.gitignore` excludes Terraform state/cache files (`*.tfstate`, `.terraform/`, `.terraform.lock.hcl`) and common credential files (`*.pem`, `*.env`) from version control.
- Make sure the S3 bucket and DynamoDB table referenced in the backend configuration already exist before running `terraform init`, as Terraform does not create backend resources automatically.
