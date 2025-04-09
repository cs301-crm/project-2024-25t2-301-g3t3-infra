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
  default     = "main"
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

# variable "amplify_logging_role" {
#   type        = string
#   description = "iam amplify logging role"
  # default     = "arn:aws:iam::345215350058:role/service-role/AmplifySSRLoggingRole-be374fb5-3a88-4787-b5d3-34c24e48878e" # should this be a secret?
# }