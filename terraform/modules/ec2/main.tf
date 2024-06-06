###############################
# Filter AMI id
###############################
data "aws_ami" "ami_src" {
  most_recent = true

  // aws owner
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"]
  }
}

###############################
# EC2
###############################

resource "null_resource" "keypair" {
  provisioner "local-exec" {
    on_failure = fail
    command    = <<EOF
    #!/bin/bash
    aws ec2 create-key-pair \
      --key-name ${var.key_name} \
      --key-type rsa \
      --key-format pem \
      --query "KeyMaterial" \
      --output text > ${var.key_name}.pem && \
      chmod 400 ${var.key_name}.pem
    EOF
  }
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ami_src.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.sg_id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  depends_on                  = [null_resource.keypair]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Remove keypair after destroy instance
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ./${self.key_name}.pem && aws ec2 delete-key-pair --key-name ${self.key_name}"
  }

  user_data = file("./nginx.sh")

  user_data_replace_on_change = true

  tags = {
    Name        = "web-server"
    Terraform   = true
    Environment = "dev"
  }
}


###############################
# AutoScaling
###############################

resource "aws_launch_template" "ec2_launch_template" {
  count       = var.enable_auto_scaling_group == true ? 1 : 0
  name        = "ec2_launch_template"
  description = "EC2 Launch template for Auto Scaling Group"

  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
      encrypted = true
      volume_type = "gp3"
    }
  }

  ebs_optimized = true

  image_id = data.aws_ami.ami_src.id

  instance_initiated_shutdown_behavior = "terminate"

  key_name = var.key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
  }

  vpc_security_group_ids = [var.sg_id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "ASG-EC2"
      Terraform   = true
      Environment = "dev"
    }
  }

  user_data = filebase64("${path.cwd}/nginx.sh")
}

resource "aws_autoscaling_group" "asg_ec2" {
  count = var.enable_auto_scaling_group == true ? 1 : 0
  max_size = var.max_size
  min_size = var.min_size
  desired_capacity = var.desired_capacity
  vpc_zone_identifier = [var.subnet_id]
  
  health_check_grace_period = 300
  health_check_type         = "ELB"

  launch_template {
    id = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
}

###############################
# AutoScaling Policy Scale out (Add more instance)
###############################

resource "aws_autoscaling_policy" "asg_policy_out" {
  count = var.enable_auto_scaling_group == true ? 1 : 0
  name                   = "asg_policy_out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg_ec2.name
}
resource "aws_cloudwatch_metric_alarm" "asg_cpu_alarm_out" {
  count = var.enable_auto_scaling_group == true ? 1 : 0
  alarm_name          = "asg_cpu_alarm_out"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg_ec2.name}"
  }
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.asg_policy_out.arn]
}


###############################
# AutoScaling Policy Scale in (Remove instance)
###############################

resource "aws_autoscaling_policy" "asg_policy_in" {
  count = var.enable_auto_scaling_group == true ? 1 : 0
  name                   = "asg_policy_in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg_ec2.name
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_alarm_in" {
  count = var.enable_auto_scaling_group == true ? 1 : 0
  alarm_name          = "asg_cpu_alarm_in"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg_ec2.name}"
  }
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.asg_policy_in.arn]
}