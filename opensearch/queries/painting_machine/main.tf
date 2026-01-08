data "terraform_remote_state" "opensearch" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "opensearch/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "lambda" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "lambda/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "sns" {
  backend = "s3"
  config = {
    bucket = "factory-tycoon-terraform-state"
    key    = "sns/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

locals {
  monitors = [
    {
      name = "painting_machine_trigger_1"
      index = "painting-index"
      query = jsonencode({
        "size": 0,
        "query": {"term": {"alert": true}}
      })
    },
    {
      name = "painting_machine_trigger_2"
      index = "painting-index"
      query = jsonencode({
        "size": 0,
        "query": {"range": {"temperature": {"gt": 80}}}
      })
    },
    {
      name = "painting_machine_trigger_3"
      index = "painting-index"
      query = jsonencode({
        "size": 0,
        "query": {"range": {"humidity": {"gt": 70}}}
      })
    }
  ]
}

resource "null_resource" "sns_channel" {
  triggers = {
    name      = "factory-tycoon-sns-channel"
    topic_arn = data.terraform_remote_state.sns.outputs.topic_arn
    role_arn  = data.terraform_remote_state.sns.outputs.opensearch_notifications_role_arn
  }

  provisioner "local-exec" {
    command = <<EOT
set -euo pipefail
BASE_URL=${data.terraform_remote_state.opensearch.outputs.endpoint}
AUTH="-u ${data.terraform_remote_state.opensearch.outputs.master_user_name}:${data.terraform_remote_state.opensearch.outputs.master_user_password}"
NAME="${self.triggers.name}"

LIST=$(curl -s -X GET $AUTH -H "Content-Type: application/json" "$BASE_URL/_plugins/_notifications/configs?from=0&size=200")
CONFIG_ID=$(echo "$LIST" | jq -r --arg NAME "$NAME" '.data.config_list[] | select(.config.name==$NAME) | .config_id' | head -n1)

if [ -z "$CONFIG_ID" ] || [ "$CONFIG_ID" = "null" ]; then
  CREATE=$(curl -s -X POST $AUTH -H "Content-Type: application/json" "$BASE_URL/_plugins/_notifications/configs" -d '{
    "config": {
      "name": "'"$NAME"'",
      "config_type": "sns",
      "is_enabled": true,
      "sns": {
        "role_arn": "${self.triggers.role_arn}",
        "topic_arn": "${self.triggers.topic_arn}"
      }
    }
  }')
  CONFIG_ID=$(echo "$CREATE" | jq -r '.config_id')
fi

echo -n "$CONFIG_ID" > sns_channel_id.txt
EOT
  }
}

resource "null_resource" "create_monitors" {
  count = length(local.monitors)

  triggers = {
    name  = local.monitors[count.index].name
    index = local.monitors[count.index].index
    query = local.monitors[count.index].query
  }

  provisioner "local-exec" {
    command = <<EOT
CONFIG_ID=$(cat sns_channel_id.txt)
curl -s -X POST \
  -H "Content-Type: application/json" \
  -u ${data.terraform_remote_state.opensearch.outputs.master_user_name}:${data.terraform_remote_state.opensearch.outputs.master_user_password} \
  ${data.terraform_remote_state.opensearch.outputs.endpoint}/_plugins/_alerting/monitors \
  -d '{
    "name": "${self.triggers.name}",
    "type": "query_level",
    "enabled": true,
    "schedule": {"interval": {"period": 1, "unit": "MINUTES"}},
    "inputs": [{
      "search": {
        "indices": ["${self.triggers.index}"],
        "query": ${self.triggers.query}
      }
    }],
    "triggers": [{
      "name": "${self.triggers.name}-trigger",
      "severity": "1",
      "condition": {
        "script": {"source": "return ctx.results[0].hits.total.value > 0"}
      },
      "actions": [{
        "name": "publish-to-sns",
        "destination_id": "'"$CONFIG_ID"'",
        "subject_template": {"source": "opensearch alert"},
        "message_template": {"source": "{{ctx}}"}
      }]
    }]
  }'
EOT
  }

  depends_on = [null_resource.sns_channel]
}
