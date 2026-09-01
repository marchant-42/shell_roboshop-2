#!/bin/bash
souce ./common_script.sh
app_name="frontend"

check_root

dnf module disable nginx -y &>>$LOGS_FILE
VALIDATE $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "enabling nginx:1.24"

dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOGS_FILE
systemctl start nginx 
VALIDATE $? "starting nginx service"

rm -rf /usr/share/nginx/html/* &>>$LOGS_FILE
VALIDATE $? "removing default nginx content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
VALIDATE $? "downloading frontend zip file"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "unzipping frontend zip file"

rm -rf /etc/nginx/nginx.conf &>>$LOGS_FILE
VALIDATE $? "removing default nginx.conf file"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copying nginx.conf file"

systemctl restart nginx &>>$LOGS_FILE
VALIDATE $? "restarting nginx service"
# satish marchant