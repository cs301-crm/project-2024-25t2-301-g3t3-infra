# IAM for Transfer Family server
data "aws_iam_policy_document" "transfer_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "transfer_logging_role" {
  name               = "transfer_logging_role"
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json
}

resource "aws_iam_role_policy_attachment" "iam_for_transfer_logging" {
  role       = aws_iam_role.transfer_logging_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

data "aws_iam_policy_document" "transfer_s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      var.sftp_bucket_arn,
      "${var.sftp_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "transfer_s3_policy" {
  name        = "transfer_s3_policy"
  description = "Policy for transfer s3 role"
  policy      = data.aws_iam_policy_document.transfer_s3_policy.json
}

resource "aws_iam_role_policy_attachment" "iam_for_transfer_s3" {
  role       = aws_iam_role.transfer_s3_role.name
  policy_arn = aws_iam_policy.transfer_s3_policy.arn
}

resource "aws_iam_role" "transfer_s3_role" {
  name               = "transfer_s3_role"
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json
}

# IAM for monetary_transactions lambda
data "aws_iam_policy_document" "process_monetary_transactions_lambda_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = [
      var.user_aurora_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      var.sftp_bucket_arn,
      "${var.sftp_bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      var.aurora_kms_key_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.user_aurora_secret_arn
    ]
  }

}

resource "aws_iam_role" "process_monetary_transactions_lambda_role" {
  name               = "process_monetary_transactions_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.process_monetary_transactions_lambda_policy_document.json
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_monetary_transactions_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.sftp_bucket_arn

  depends_on = [aws_iam_role.process_monetary_transactions_lambda_role]
}

resource "aws_lambda_function" "process_monetary_transactions_lambda" {
  filename      = "dummy.zip"
  function_name = "process_monetary_transactions"
  role          = aws_iam_role.process_monetary_transactions_lambda_role.arn
  handler       = "exports.example"
  runtime       = "python3.13"
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.process_monetary_transactions_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# EKS RELATED ROLES
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks" {
  name = "eks-cluster-prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prod-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  # Grant access to EC2 and EKS
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_user" "dev" {
  name = "dev"
}

resource "aws_iam_policy" "dev_eks" {
  name = "AmazonEKSDeveloperPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "dev_eks" {
  user       = aws_iam_user.dev.name
  policy_arn = aws_iam_policy.dev_eks.arn
}

resource "awscc_eks_access_entry" "dev" {
  cluster_name      = var.eks_cluster_name
  principal_arn     = aws_iam_user.dev.arn
  kubernetes_groups = ["eks-viewer"]
}

resource "aws_iam_role" "eks_admin" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "eks_admin" {
  name = "AmazonEKSAdminPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "eks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = aws_iam_policy.eks_admin.arn
}

resource "aws_iam_user" "manager" {
  name = "manager"
}

resource "aws_iam_policy" "eks_assume_admin" {
  name = "AmazonEKSAssumeAdminPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "${aws_iam_role.eks_admin.arn}"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "manager" {
  user       = aws_iam_user.manager.name
  policy_arn = aws_iam_policy.eks_assume_admin.arn
}

resource "aws_eks_access_entry" "admin" {
  cluster_name      = var.eks_cluster_name
  principal_arn     = aws_iam_role.eks_admin.arn
  kubernetes_groups = ["eks-admin"]
}

# POD ASSUME POLICY
data "aws_iam_policy_document" "pod_assume_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      identifiers = ["pods.eks.amazonaws.com"]
      type        = "Service"
    }
  }
}

# EKS CLUSTER AUTOSCALER
resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.eks_cluster_name}-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.eks_cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.pod_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

resource "awscc_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = var.eks_cluster_name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

# EKS LBC
resource "aws_iam_policy" "aws_lbc" {
  name   = "AWSLoadBalancerController"
  policy = file("${path.module}/policies/AWSLoadBalancerController.json")
}

resource "aws_iam_role" "aws_lbc" {
  name               = "${var.eks_cluster_name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.pod_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

resource "awscc_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = var.eks_cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
}

resource "aws_iam_role" "argocd_image_updater" {
  name               = "${var.eks_cluster_name}-argocd-image-updater"
  assume_role_policy = data.aws_iam_policy_document.pod_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "argocd_image_updater" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.argocd_image_updater.name
}

resource "aws_eks_pod_identity_association" "argocd_image_updater" {
  cluster_name    = var.eks_cluster_name
  namespace       = "argocd"
  service_account = "argocd-image-updater"
  role_arn        = aws_iam_role.argocd_image_updater.arn
}


resource "aws_iam_role" "efs_csi_driver" {
  name               = "${var.eks_cluster_name}-efs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.pod_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver.name
}

resource "awscc_eks_pod_identity_association" "efs_csi_driver" {
  cluster_name    = var.eks_cluster_name
  namespace       = "kube-system"
  service_account = "efs-csi-driver-controller-sa"
  role_arn        = aws_iam_role.efs_csi_driver.arn
}


resource "aws_iam_role" "scrooge_bank_secrets" {
  name               = "${var.eks_cluster_name}-scrooge_bank_secrets"
  assume_role_policy = data.aws_iam_policy_document.pod_assume_policy.json
}

resource "aws_iam_policy" "scrooge_bank_secrets" {
  name = "${var.eks_cluster_name}-scrooge-bank-secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scrooge_bank_secrets" {
  policy_arn = aws_iam_policy.scrooge_bank_secrets.arn
  role       = aws_iam_role.scrooge_bank_secrets.name
}

resource "awscc_eks_pod_identity_association" "scrooge_bank_secrets" {
  cluster_name    = var.eks_cluster_name
  namespace       = "default"
  service_account = "scrooge-bank-secrets"
  role_arn        = aws_iam_role.scrooge_bank_secrets.arn
}