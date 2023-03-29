#!/bin/sh
eval "userName=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text | jq .userName)"
eval "accountId=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text | jq .accountId)"
eval "apiToken=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text | jq .apiToken)"
eval "datadogToken=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text | jq .datadogToken)"
eval "region=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query SecretString --output text | jq .customerDefaultRegion)"
export authToken="BOOMI_TOKEN.$userName:$apiToken"
