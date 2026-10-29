# Dynamically query production instances with their full attributes
data "aws_instances" "app_nodes" {
  filter {
    name   = "tag:Environment"
    values = ["production"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running", "stopped"]
  }
}

# Convert the set of instance IDs to a sorted list
# for stable indexing
locals {
  instance_ids = sort(tolist(data.aws_instances.app_nodes.ids))
}

# Fetch details for each selected instance
data "aws_instance" "node_details" {
  count = var.instance_count

  instance_id = local.instance_ids[count.index]

  lifecycle {
    postcondition {
      condition     = length(local.instance_ids) >= var.instance_count
      error_message = "var.instance_count exceeds the number of production instances found."
    }
  }
}

# Create an AMI from the first instance (Golden Image)
resource "aws_ami_from_instance" "golden_ami" {
  name                    = "app-instance-1-golden-ami"
  source_instance_id      = data.aws_instance.node_details[0].id
  snapshot_without_reboot = true

  tags = {
    Environment = "production"
    Name        = "app-instance-1-golden-ami"
  }
}

# Create standalone EBS snapshots for all selected instances
# Convert root_block_device from a set to a list before indexing
resource "aws_ebs_snapshot" "node_snapshots" {
  count = var.instance_count

  volume_id = tolist(
    data.aws_instance.node_details[count.index].root_block_device
  )[0].volume_id

  description = "Manual snapshot of production root volume ${count.index + 1}"

  tags = {
    Name        = "snapshot-app-volume-${count.index + 1}"
    Environment = "production"
  }
}
