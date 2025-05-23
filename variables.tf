variable "vpc_id" {
  type        = string
  description = "Fetch the existing VPC ID"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "env" {
  type        = string
  description = "Application environment"
}

variable "region" {
  type        = string
  description = "AWS default region"
}

variable "datadog_api_key" {
  type        = string
  description = "Data dog api key"
  sensitive   = true
}