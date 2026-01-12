# OpenSearch Triggers Configuration
# 각 Monitor마다 3개의 Trigger (Yellow, Orange, Red)를 설정합니다
# Trigger 로직은 Groovy 스크립트로 구현됩니다

# ============================================================================
# Painting (도색) Process Triggers
# ============================================================================

# Painting Yellow Trigger
locals {
  painting_yellow_condition = templatefile("${path.module}/trigger_scripts/painting_yellow.js", {
    voc_red          = var.painting_config.voc_red
    voc_orange_low   = var.painting_config.voc_orange_low
    voc_orange_high  = var.painting_config.voc_orange_high
    voc_yellow_low   = var.painting_config.voc_yellow_low
    voc_yellow_high  = var.painting_config.voc_yellow_high
    pressure_red_low    = var.painting_config.pressure_red_low
    pressure_red_high   = var.painting_config.pressure_red_high
    pressure_orange_low = var.painting_config.pressure_orange_low
    pressure_orange_high = var.painting_config.pressure_orange_high
    pressure_yellow_low = var.painting_config.pressure_yellow_low
    pressure_yellow_high = var.painting_config.pressure_yellow_high
    temp_red            = var.painting_config.temp_red
    temp_orange_low     = var.painting_config.temp_orange_low
    temp_orange_high    = var.painting_config.temp_orange_high
    temp_yellow_low     = var.painting_config.temp_yellow_low
    temp_yellow_high    = var.painting_config.temp_yellow_high
  })
}

# Painting Orange Trigger
locals {
  painting_orange_condition = templatefile("${path.module}/trigger_scripts/painting_orange.js", {
    voc_red          = var.painting_config.voc_red
    voc_orange_low   = var.painting_config.voc_orange_low
    voc_orange_high  = var.painting_config.voc_orange_high
    voc_yellow_low   = var.painting_config.voc_yellow_low
    voc_yellow_high  = var.painting_config.voc_yellow_high
    pressure_red_low    = var.painting_config.pressure_red_low
    pressure_red_high   = var.painting_config.pressure_red_high
    pressure_orange_low = var.painting_config.pressure_orange_low
    pressure_orange_high = var.painting_config.pressure_orange_high
    pressure_yellow_low = var.painting_config.pressure_yellow_low
    pressure_yellow_high = var.painting_config.pressure_yellow_high
    temp_red            = var.painting_config.temp_red
    temp_orange_low     = var.painting_config.temp_orange_low
    temp_orange_high    = var.painting_config.temp_orange_high
    temp_yellow_low     = var.painting_config.temp_yellow_low
    temp_yellow_high    = var.painting_config.temp_yellow_high
  })
}

# Painting Red Trigger
locals {
  painting_red_condition = templatefile("${path.module}/trigger_scripts/painting_red.js", {
    voc_red          = var.painting_config.voc_red
    voc_orange_low   = var.painting_config.voc_orange_low
    voc_orange_high  = var.painting_config.voc_orange_high
    voc_yellow_low   = var.painting_config.voc_yellow_low
    voc_yellow_high  = var.painting_config.voc_yellow_high
    pressure_red_low    = var.painting_config.pressure_red_low
    pressure_red_high   = var.painting_config.pressure_red_high
    pressure_orange_low = var.painting_config.pressure_orange_low
    pressure_orange_high = var.painting_config.pressure_orange_high
    pressure_yellow_low = var.painting_config.pressure_yellow_low
    pressure_yellow_high = var.painting_config.pressure_yellow_high
    temp_red            = var.painting_config.temp_red
    temp_orange_low     = var.painting_config.temp_orange_low
    temp_orange_high    = var.painting_config.temp_orange_high
    temp_yellow_low     = var.painting_config.temp_yellow_low
    temp_yellow_high    = var.painting_config.temp_yellow_high
  })
}

# ============================================================================
# Turning (선삭) Process Triggers
# ============================================================================

# Turning Yellow Trigger
locals {
  turning_yellow_condition = templatefile("${path.module}/trigger_scripts/turning_yellow.js", {
    rpm_red_low     = var.turning_config.rpm_red_low
    rpm_orange_low  = var.turning_config.rpm_orange_low
    rpm_orange_high = var.turning_config.rpm_orange_high
    rpm_yellow_low  = var.turning_config.rpm_yellow_low
    rpm_yellow_high = var.turning_config.rpm_yellow_high
    rpm_orange_high2 = var.turning_config.rpm_orange_high2
    noise_red           = var.turning_config.noise_red
    noise_orange_low    = var.turning_config.noise_orange_low
    noise_orange_high   = var.turning_config.noise_orange_high
    noise_yellow_low    = var.turning_config.noise_yellow_low
    noise_yellow_high   = var.turning_config.noise_yellow_high
    displacement_red         = var.turning_config.displacement_red
    displacement_orange_low  = var.turning_config.displacement_orange_low
    displacement_orange_high = var.turning_config.displacement_orange_high
    displacement_yellow_low  = var.turning_config.displacement_yellow_low
    displacement_yellow_high = var.turning_config.displacement_yellow_high
  })
}

# Turning Orange Trigger
locals {
  turning_orange_condition = templatefile("${path.module}/trigger_scripts/turning_orange.js", {
    rpm_red_low     = var.turning_config.rpm_red_low
    rpm_orange_low  = var.turning_config.rpm_orange_low
    rpm_orange_high = var.turning_config.rpm_orange_high
    rpm_yellow_low  = var.turning_config.rpm_yellow_low
    rpm_yellow_high = var.turning_config.rpm_yellow_high
    rpm_orange_high2 = var.turning_config.rpm_orange_high2
    noise_red           = var.turning_config.noise_red
    noise_orange_low    = var.turning_config.noise_orange_low
    noise_orange_high   = var.turning_config.noise_orange_high
    noise_yellow_low    = var.turning_config.noise_yellow_low
    noise_yellow_high   = var.turning_config.noise_yellow_high
    displacement_red         = var.turning_config.displacement_red
    displacement_orange_low  = var.turning_config.displacement_orange_low
    displacement_orange_high = var.turning_config.displacement_orange_high
    displacement_yellow_low  = var.turning_config.displacement_yellow_low
    displacement_yellow_high = var.turning_config.displacement_yellow_high
  })
}

# Turning Red Trigger
locals {
  turning_red_condition = templatefile("${path.module}/trigger_scripts/turning_red.js", {
    rpm_red_low     = var.turning_config.rpm_red_low
    rpm_orange_low  = var.turning_config.rpm_orange_low
    rpm_orange_high = var.turning_config.rpm_orange_high
    rpm_yellow_low  = var.turning_config.rpm_yellow_low
    rpm_yellow_high = var.turning_config.rpm_yellow_high
    rpm_orange_high2 = var.turning_config.rpm_orange_high2
    noise_red           = var.turning_config.noise_red
    noise_orange_low    = var.turning_config.noise_orange_low
    noise_orange_high   = var.turning_config.noise_orange_high
    noise_yellow_low    = var.turning_config.noise_yellow_low
    noise_yellow_high   = var.turning_config.noise_yellow_high
    displacement_red         = var.turning_config.displacement_red
    displacement_orange_low  = var.turning_config.displacement_orange_low
    displacement_orange_high = var.turning_config.displacement_orange_high
    displacement_yellow_low  = var.turning_config.displacement_yellow_low
    displacement_yellow_high = var.turning_config.displacement_yellow_high
  })
}

# ============================================================================
# Local variables for SNS Topic
# ============================================================================

locals {
  sns_topic_arn = var.sns_topic_arn != "" ? var.sns_topic_arn : try(data.terraform_remote_state.sns.outputs.sns_topic_arn, "")
  lambda_function_arn = var.lambda_function_arn != "" ? var.lambda_function_arn : try(data.terraform_remote_state.lambda.outputs.opensearch_to_mariadb_function_arn, "")
}

# Note: OpenSearch Provider의 Trigger 리소스는 REST API를 통해 직접 관리할 수도 있습니다.
# 현재는 Terraform OpenSearch Provider의 제한으로 인해 Trigger는 수동 설정 또는
# null_resource + local-exec을 통해 AWS CLI로 관리할 수 있습니다.
# 이 파일은 Trigger 조건 로직과 설정값을 코드로 관리하기 위한 변수와 스크립트를 정의합니다.

