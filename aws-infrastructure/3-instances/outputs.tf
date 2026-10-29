output "instance_ids" {
  value = aws_instance.app_node[*].id
}

output "root_volume_ids" {
  value = aws_instance.app_node[*].root_block_device[0].volume_id
}
