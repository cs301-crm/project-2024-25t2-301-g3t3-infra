variable "repository" {
    type = string
    description = "github repo url"
    default = "https://github.com/cs301-crm/project-2024-25t2-301-g3t3-frontend"
}

variable "app_name" { 
    type = string
    description = "aws amplify app name"
    default = "scrooge-bank-crm"
}

variable "branch_name" {
    type = string
    description = "aws amplify app repo branch name"
    default = "main"
}

variable "domain_name" {
    type = string
    description = "aws amplify domain name"
    default = "itsag3t3.com"
}