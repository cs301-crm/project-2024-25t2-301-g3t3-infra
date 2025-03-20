terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "scrooge-bank-g3t3-terraform-state"
    key    = "global/main.tfstate"
    region = "ap-southeast-1" # cannot use variable because this is used before variables are declared
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_amplify_app" "amplify_app" {
  name        = var.app_name
  repository  = var.repository
  oauth_token = jsondecode(data.aws_secretsmanager_secret_version.github_token.secret_string)["github-token"]

  platform = "WEB_COMPUTE"

  # The default build_spec added by the Amplify Console for Next
  build_spec = <<-EOT
  version: 1
  frontend:
    phases:
      preBuild:
        commands:
          - npm ci --cache .npm --prefer-offline
      build:
        commands:
          - npm run build
    artifacts:
      baseDirectory: .next
      files:
        - '**/*'
    cache:
      paths:
        - .next/cache/**/*
        - .npm/**/*
  EOT

  # The default rewrites and redirects added by the Amplify Console.
  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }

  iam_service_role_arn = "arn:aws:iam::345215350058:role/service-role/AmplifySSRLoggingRole-be374fb5-3a88-4787-b5d3-34c24e48878e"
}

resource "aws_amplify_branch" "amplify_branch" {
  app_id            = aws_amplify_app.amplify_app.id
  branch_name       = var.branch_name
  enable_auto_build = true
  stage = "PRODUCTION"
  framework         = "Next.js - SSR"
}

# hosted zone
resource "aws_route53_zone" "main" {
  name = "itsag3t3.com"
}

# associate custom domain 
resource "aws_amplify_domain_association" "domain_association" {
  app_id                = aws_amplify_app.amplify_app.id
  domain_name           = var.domain_name
  wait_for_verification = false

  sub_domain {
    branch_name = aws_amplify_branch.amplify_branch.branch_name
    prefix      = "" # root domain
  }

  sub_domain {
    branch_name = aws_amplify_branch.amplify_branch.branch_name
    prefix      = "www" 
  }
}

# route 53 alias
resource "aws_route53_record" "root_domain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "itsag3t3.com"
  type    = "A"

  alias {
    name                   = aws_amplify_domain_association.domain_association.domain_name
    zone_id                = aws_route53_zone.main.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_subdomain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.itsag3t3.com"
  type    = "A"

  alias {
    name                   = aws_amplify_domain_association.domain_association.domain_name
    zone_id                = aws_route53_zone.main.zone_id
    evaluate_target_health = false
  }
}

# Trigger Amplify deployment job after app setup
resource "null_resource" "trigger_amplify_deploy" {
  #   depends_on = [aws_amplify_domain_association.domain_association]
  depends_on = [aws_amplify_branch.amplify_branch]


  provisioner "local-exec" {
    command = "aws amplify start-job --app-id ${aws_amplify_app.amplify_app.id} --branch-name ${var.branch_name} --job-type RELEASE"
  }
}