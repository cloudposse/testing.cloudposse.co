region = "us-east-2"

name = "trader_page_stats"

billing_mode = "PAY_PER_REQUEST"

hash_key = "trader_id"

hash_key_type = "N"

range_key = "ds"

range_key_type = "S"

ttl_attribute = ""

dynamodb_attributes = [
  {
    name = "lookup_count"
    type = "N"
  },
  {
    name = "search_count"
    type = "N"
  },
  {
    name = "external_count"
    type = "N"
  },
  {
    name = "total_count"
    type = "N"
  },
  {
    name = "site"
    type = "N"
  }
]

global_secondary_index_map = []

local_secondary_index_map = []

chamber_parameters_enabled = false

dynamodb_chamber_service = "dynamodb"

enable_streams = false

stream_view_type = ""

enable_encryption = true

enable_point_in_time_recovery = true

enable_autoscaler = true

autoscale_write_target = 50

autoscale_read_target = 50

autoscale_min_read_capacity = 5

autoscale_max_read_capacity = 20

autoscale_min_write_capacity = 5

autoscale_max_write_capacity = 20

enable_backup = true

backup_kms_key_arn = ""

backup_schedule = "cron(0 12 * * ? *)"

backup_start_window = 10

backup_completion_window = 70

backup_cold_storage_after = 180

backup_delete_after = 360
