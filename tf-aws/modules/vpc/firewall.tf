resource "aws_networkfirewall_firewall" "networkfirewall" {
  name                = "scrooge-bank"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.networkfirewall_policy.arn
  vpc_id              = aws_vpc.vpc.id
  subnet_mapping {
    subnet_id = aws_subnet.public_subnet_1.id
  }
  subnet_mapping {
    subnet_id = aws_subnet.public_subnet_2.id
  }

  timeouts {
    create = "40m"
    update = "50m"
    delete = "1h"
  }
}

resource "aws_networkfirewall_firewall_policy" "networkfirewall_policy" {
  name        = "scrooge-bank"
  description = "only from scrooge bank"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.web_access.arn
    }
  }
}

resource "aws_networkfirewall_rule_group" "web_access" {
  capacity = 100
  name     = "web-access"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "80"
          direction        = "ANY"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }

      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "443"
          direction        = "ANY"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["2"]
        }
      }

      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "22"
          direction        = "ANY"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["3"]
        }
      }
    }
  }
}


resource "aws_networkfirewall_logging_configuration" "networkfirewall_log_config" {
  firewall_arn = aws_networkfirewall_firewall.networkfirewall.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.networkfirewall_log_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

resource "aws_cloudwatch_log_group" "networkfirewall_log_group" {
  name_prefix       = "network_firewall_"
  retention_in_days = 30
}