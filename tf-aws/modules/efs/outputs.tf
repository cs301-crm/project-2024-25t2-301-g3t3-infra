output "efs_mount_targets" {
  description = "Mount targets for EFS"
  value = concat(aws_efs_mount_target.zone_a, aws_efs_mount_target.zone_b)
}