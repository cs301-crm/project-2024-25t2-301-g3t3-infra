variable "public_subnet_id" {}
variable "bastion_sg" {}
variable "bastion_iam_instance_profile" {}
variable "msk_cluster_bootstrap_brokers" {}

resource "aws_instance" "bastion" {
  ami                    = "ami-0b5a4445ada4a59b1" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg]
  key_name               = "cs301 bastion"
  iam_instance_profile   = var.bastion_iam_instance_profile

  user_data = <<-EOL
  #!/bin/bash -xe

  sudo yum install -y postgresql16 postgresql16-server
  sudo /usr/bin/postgresql-setup --initdb
  sudo systemctl start postgresql
  sudo systemctl enable postgresql

  # Install Kafka client tools
  sudo yum install -y java-17-amazon-corretto 
  wget https://dlcdn.apache.org/kafka/4.0.0/kafka_2.13-4.0.0.tgz
  tar -xzf kafka_2.13-4.0.0.tgz
  rm kafka_2.13-4.0.0.tgz
  sudo mv kafka_2.13-4.0.0 /opt/kafka
  sudo chmod -R 755 /opt/kafka
  echo 'export PATH="$PATH:/opt/kafka/bin"' >> ~/.bashrc
  source ~/.bashrc
  EOL

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
    for i in {1..5}; do
      if echo "ls" | timeout 5 kafka-topics.sh --bootstrap-server $BOOTSTRAP_BROKERS --list; then
        echo "Successfully connected to Kafka brokers!"
        break
      fi
      
      if [ $i -eq 5 ]; then
        echo "Failed to connect to Kafka brokers after 5 attempts"
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