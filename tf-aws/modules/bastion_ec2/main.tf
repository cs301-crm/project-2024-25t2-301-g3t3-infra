variable "public_subnet_id" {}
variable "bastion_sg" {}
variable "bastion_iam_instance_profile" {}
variable "msk_cluster_bootstrap_brokers" {}

resource "aws_instance" "bastion" {
  ami                    = "ami-0b83b6b68fae94127" # bastion host AMI
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg]
  key_name               = "cs301 bastion"
  iam_instance_profile   = var.bastion_iam_instance_profile

  tags = {
    Name = "bastion-host"
  }
}

# create a script to bootstrap msk topics on the bastion host
resource "null_resource" "create_topic_script" {
  depends_on = [aws_instance.bastion, var.msk_cluster_bootstrap_brokers]

  # copy script to bastion host
  provisioner "file" {
    content = <<-EOF
    #!/bin/bash

    # Get broker information
    BOOTSTRAP_BROKERS="${var.msk_cluster_bootstrap_brokers}"

    # Verify broker connection
    echo "verifying broker connectivity..."
    for i in {1..8}; do
      if echo "ls" | timeout 10 kafka-topics.sh --bootstrap-server $BOOTSTRAP_BROKERS --list; then
        echo "Successfully connected to Kafka brokers!"
        break
      fi
      
      if [ $i -eq 8 ]; then
        echo "Failed to connect to Kafka brokers after 8 attempts"
        exit 1
      fi
      
      echo $BOOTSTRAP_BROKERS
      echo "Attempt $i failed. Retrying in 10 seconds..."
      sleep 10
    done

    # Create topics
    echo "Creating topic: logs"
    kafka-topics.sh --create --topic logs --partitions 100 --replication-factor 3 \
      --bootstrap-server $BOOTSTRAP_BROKERS \
      --config segment.ms=20000 \
      --config cleanup.policy=compact
    
    echo "Creating topic: otps"
    kafka-topics.sh --create --topic otps --partitions 100 --replication-factor 3 \
      --bootstrap-server $BOOTSTRAP_BROKERS \
      --config segment.ms=20000 \
      --config cleanup.policy=compact
    
    echo "Creating topic: u2c"
    kafka-topics.sh --create --topic u2c --partitions 100 --replication-factor 3 \
      --bootstrap-server $BOOTSTRAP_BROKERS \
      --config segment.ms=20000 \
      --config cleanup.policy=compact
    
    echo "Creating topic: a2c"
    kafka-topics.sh --create --topic a2c --partitions 100 --replication-factor 3 \
      --bootstrap-server $BOOTSTRAP_BROKERS \
      --config segment.ms=20000 \
      --config cleanup.policy=compact

    echo "Creating topic: c2c"
    kafka-topics.sh --create --topic c2c --partitions 100 --replication-factor 3 \
      --bootstrap-server $BOOTSTRAP_BROKERS \
      --config segment.ms=20000 \
      --config cleanup.policy=compact

    echo "Listing all topics:"
    kafka-topics.sh --bootstrap-server $BOOTSTRAP_BROKERS --list
    EOF

    destination = "/tmp/create_topics.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/cs301-bastion.pem")
      host        = aws_instance.bastion.public_ip
    }
  }

  # Make the script executable and run it
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_topics.sh",
      "/tmp/create_topics.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/cs301-bastion.pem")
      host        = aws_instance.bastion.public_ip
    }
  }
}