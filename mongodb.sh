#!/bin/bash
source ./common_script.sh
app_name=mongodb

check_root

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo.repo"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "installing mongo server"

systemctl enable mongod &>>$LOGS_FILE
systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "updating mongodb confi file for remote connections"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "restarting mongodb"

print_time
