# DynamoDB table for storing meal nutrition data
resource "aws_dynamodb_table" "kbju_meals" {
  name           = "kbju_meals"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "timestamp"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # Enable point-in-time recovery for data protection
  point_in_time_recovery {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "kbju_meals"
    Environment = var.environment
    Project     = "mealmeter"
  }
}
