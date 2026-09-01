#!/bin/bash
source ./common_script.sh
app_name="redis"

check_root

dnf module disable redis -y &>>$LOGS_FILE
VALIDATE $? "disabling redis module"

dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "enabling redis:7 module"

dnf install redis -y &>>$LOGS_FILE
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e ' /protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "updating redis confi file for remote connections"

systemctl enable redis &>>$LOGS_FILE
VALIDATE $? "enabling redis service"
systemctl start redis &>>$LOGS_FILE
VALIDATE $? "starting redis service"

print_time
