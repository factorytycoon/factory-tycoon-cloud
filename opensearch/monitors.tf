# OpenSearch Monitors for Factory Tycoon
# 세 가지 생산 공정별 모니터링: Inspection, Painting, Turning

# ============================================================================
# 1. Inspection (검수) Monitor - ft-pi-004
# ============================================================================

resource "opensearch_monitor" "inspection" {
  name            = "factory-inspection-monitor"
  monitor_type    = "per_query_monitor"
  enabled         = true
  schedule_period = 1
  schedule_unit   = "MINUTES"

  monitor_query = jsonencode({
    size = 1
    query = {
      bool = {
        filter = [
          {
            range = {
              processed_at = {
                from = "now-1m"
                to   = "now"
                include_lower = true
                include_upper = true
              }
            }
          },
          {
            term = {
              device_id = {
                value = "ft-pi-004"
              }
            }
          }
        ]
        adjust_pure_negative = true
      }
    }
    sort = [
      {
        processed_at = {
          order = "desc"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "inspection-monitor"
      Process = "Inspection"
    }
  )

  depends_on = [aws_opensearch_domain.main]
}

# ============================================================================
# 2. Painting (도색) Monitor - ft-pi-003
# ============================================================================

resource "opensearch_monitor" "painting" {
  name            = "factory-painting-monitor"
  monitor_type    = "per_query_monitor"
  enabled         = true
  schedule_period = 1
  schedule_unit   = "MINUTES"

  monitor_query = jsonencode({
    size = 1
    query = {
      bool = {
        filter = [
          {
            range = {
              processed_at = {
                from = "now-1m"
                to   = "now"
                include_lower = true
                include_upper = true
              }
            }
          },
          {
            term = {
              device_id = {
                value = "ft-pi-003"
              }
            }
          }
        ]
        adjust_pure_negative = true
      }
    }
    sort = [
      {
        processed_at = {
          order = "desc"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "painting-monitor"
      Process = "Painting"
    }
  )

  depends_on = [aws_opensearch_domain.main]
}

# ============================================================================
# 3. Turning (선삭) Monitor - ft-pi-002
# ============================================================================

resource "opensearch_monitor" "turning" {
  name            = "factory-turning-monitor"
  monitor_type    = "per_query_monitor"
  enabled         = true
  schedule_period = 1
  schedule_unit   = "MINUTES"

  monitor_query = jsonencode({
    size = 1
    query = {
      bool = {
        filter = [
          {
            range = {
              processed_at = {
                from = "now-1m"
                to   = "now"
                include_lower = true
                include_upper = true
              }
            }
          },
          {
            term = {
              device_id = {
                value = "ft-pi-002"
              }
            }
          }
        ]
        adjust_pure_negative = true
      }
    }
    sort = [
      {
        processed_at = {
          order = "desc"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "turning-monitor"
      Process = "Turning"
    }
  )

  depends_on = [aws_opensearch_domain.main]
}
