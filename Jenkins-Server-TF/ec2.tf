resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ami.image_id
  instance_type          = "t3a.xlarge"  # Cost-optimized: 4 vCPUs, 16GB RAM - Perfect for DevSecOps workload
  key_name               = var.key-name
  subnet_id              = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name
  root_block_device {
    volume_size = 40  # Increased from 30GB for better performance
  }
  user_data = templatefile("./tools-install.sh", {})

  tags = {
    Name = var.instance-name
  }
}