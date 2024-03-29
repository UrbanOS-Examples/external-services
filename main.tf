provider "aws" {
  version = "~> 3.0"
  region  = var.region

  assume_role {
    role_arn = var.role_arn
  }
}

data "terraform_remote_state" "env_remote_state" {
  backend   = "s3"
  workspace = terraform.workspace

  config = {
    bucket   = var.alm_state_bucket_name
    key      = "operating-system"
    region   = "us-east-2"
    role_arn = var.alm_role_arn
  }
}

resource "local_file" "kubeconfig" {
  filename = "${path.module}/outputs/kubeconfig"
  content  = data.terraform_remote_state.env_remote_state.outputs.eks_cluster_kubeconfig
}

resource "local_file" "helm_vars" {
  filename = "${path.module}/outputs/${terraform.workspace}.yaml"

  content = <<EOF
alm:
  dns_zone: "${var.alm_dns_zone}"
services:
- hostname: "iam-master.${var.alm_dns_zone}"
  name: ldap
EOF

}

resource "null_resource" "helm_deploy" {
  provisioner "local-exec" {
    command = <<EOF
set -x

export KUBECONFIG=${local_file.kubeconfig.filename}

export AWS_DEFAULT_REGION=us-east-2
helm repo add scdp https://urbanos-public.github.io/charts/
helm repo update
helm upgrade --install external-services scdp/external-services --namespace=external-services \
  --values ${local_file.helm_vars.filename}
EOF

  }

  triggers = {
    # Triggers a list of values that, when changed, will cause the resource to be recreated
    # ${uuid()} will always be different thus always executing above local-exec
    hack_that_always_forces_null_resources_to_execute = uuid()
  }
}

variable "region" {
  description = "Region of ALM resources"
  default     = "us-west-2"
}

variable "role_arn" {
  description = "The ARN for the assume role for ALM access"
  default     = "arn:aws:iam::199837183662:role/jenkins_role"
}

variable "alm_role_arn" {
  description = "The ARN for the assume role for ALM access"
  default     = "arn:aws:iam::199837183662:role/jenkins_role"
}

variable "alm_state_bucket_name" {
  description = "The name of the S3 state bucket for ALM"
  default     = "scos-alm-terraform-state"
}

variable "alm_dns_zone" {
  description = "DNS zone for alm"
}

