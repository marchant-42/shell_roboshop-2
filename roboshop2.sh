```bash
#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0d25319b661cf812b"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalog" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z09783873O434Q2DYUCO6"
DOMAIN_NAME="satishdevops.shop"


# For testing, passing instance names as arguments
# Example:
# bash roboshop2.sh frontend catalog mongodb

for instance in "$@"
do

    echo "Creating $instance instance..."

    # Create EC2 instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t2.micro \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)


    # Check whether instance creation was successful
    if [ $? -ne 0 ] || [ -z "$INSTANCE_ID" ]
    then
        echo "ERROR: Failed to create $instance instance"
        continue
    fi


    echo "$instance instance created: $INSTANCE_ID"


    # Wait until instance is running
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"


    # Get IP address
    if [ "$instance" != "frontend" ]
    then

        # Backend instances use Private IP
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)

        RECORD_NAME="$instance.$DOMAIN_NAME"

    else

        # Frontend uses Public IP
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)

        RECORD_NAME="$DOMAIN_NAME"

    fi


    echo "$instance IP address : $IP"


    # Create / update Route 53 record
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch '{
            "Comment": "Creating Route 53 record",
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
```
