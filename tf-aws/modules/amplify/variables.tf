variable "repository" {
  type        = string
  description = "github repo url"
  default     = "https://github.com/cs301-crm/project-2024-25t2-301-g3t3-frontend"
}

variable "app_name" {
  type        = string
  description = "aws amplify app name"
  default     = "scrooge-bank-crm"
}

variable "region" {
  type        = string
  description = "aws region"
  default     = "ap-southeast-1"
}

variable "branch_name" {
  type        = string
  description = "aws amplify app repo branch name"
  default     = "prod"
}

variable "domain_name" {
  type        = string
  description = "aws amplify domain name"
  default     = "itsag3t3.com"
}

variable "platform" {
  type        = string
  description = "amplify hosting platform"
  default     = "WEB_COMPUTE"
}