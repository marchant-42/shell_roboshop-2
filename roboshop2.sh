#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0d25319b661cf812b"
ZONE_ID="Z09783873O434Q2DYUCO6"
DOMAIN_NAME="satishdevops.shop"

for instance in "$@"
do

    echo "Creating $instance instance..."

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.small \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance}}]" \
        --query "Instances[0].InstanceId" \
        --output text)

    if [ $? -ne 0 ] || [ -z "$INSTANCE_ID" ]
    then
        echo "ERROR: Failed to create $instance instance"
        continue
    fi

    echo "$instance instance created: $INSTANCE_ID"

    aws ec2 wait instance-running \
        --instance-ids "$INSTANCE_ID"

    if [ "$instance" != "frontend" ]
    then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)

        RECORD_NAME="$instance.$DOMAIN_NAME"

    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)

        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance IP address : $IP"

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch '{
          "Comment": "Testing creating a record set",
          "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
              "Name": "'"$RECORD_NAME"'",
              "Type": "A",
              "TTL": 1,
              "ResourceRecords": [{
                "Value": "'"$IP"'"
              }]
            }
          }]
        }'

done