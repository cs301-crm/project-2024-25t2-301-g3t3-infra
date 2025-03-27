output "efs_mount_target_zone_a" {
  description = "Mount targets zone afor EFS"
  value       = aws_efs_mount_target.zone_a
}

output "efs_mount_target_zone_b" {
  description = "Mount target zone b for EFS"
  value       = aws_efs_mount_target.zone_b
}

output "efs_file_system_id" {
  value = aws_efs_file_system.eks.id
}