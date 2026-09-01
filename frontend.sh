#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script statrted excuted at : $(date)" | tee -a $LOGS_FILE
if [ $USERID -ne 0 ]
then
    echo -e "$R Error : only root user can run this script $N" | tee -a $LOGS_FILE
    exit 1
else 
    echo "you are running with root access" | tee -a $LOGS_FILE
fi
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e " $2 is ...$G success $N " | tee -a $LOGS_FILE
    else
        echo -e "$2 is $R failed $N" | tee -a $LOGS_FILE
        exit 1
    fi
}

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