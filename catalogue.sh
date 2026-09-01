#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

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
dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "disabling nodejs module"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "enabling nodejs:20 module"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "installing nodejs"

id roboshop &>$LOGS_FILE
    if [ $? -ne 0 ]
    then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "creating roboshop system user"
    else
        echo -e "roboshop user is $Y already present nothing to do $N"
    fi
    
mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "downloading catalogue zip file"

rm -rf /app/*  &>>$LOGS_FILE
cd /app
unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "unzipping catalogue zip file"

npm install &>>$LOGS_FILE
VALIDATE $? "installing nodejs dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue service file"

systemctl daemon-reload &>>$LOGS_FILE
systemctl enable catalogue &>>$LOGS_FILE
systemctl start catalogue
VALIDATE $? "starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "installing mongodb client"

STATUS=$(mongosh --host mongodb.satishdevops.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue")'
)
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.satishdevops.shop </app/db/master-data.js &>>$LOGS_FILE
    VALIDATE $? "loading data into Mongodb"
else
    echo -e "Data is alredy loaded ...$Y SKIPPING $N" 
fi

#mongosh --host mongodb.satishdevops.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue(db name)")'
#out put is 1 it means db is exists, other wise not
