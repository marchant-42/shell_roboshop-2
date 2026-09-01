#!/bin/bash

START_TIME=$(date +%s)
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

check_root(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Error : only root user can run this script $N" | tee -a $LOGS_FILE
        exit 1
    else 
        echo "you are running with root access" | tee -a $LOGS_FILE
    fi}
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e " $2 is ...$G success $N " | tee -a $LOGS_FILE
    else
        echo -e "$2 is $R failed $N" | tee -a $LOGS_FILE
        exit 1
    fi
}
app_setup(){
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

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOGS_FILE
    VALIDATE $? "downloading $app_name zip file"

    rm -rf /app/* &>>$LOGS_FILE
    cd /app
    unzip /tmp/$app_name.zip &>>$LOGS_FILE
    VALIDATE $? "unzipping $app_name zip file"
}
nodejs_setup(){
    dnf module disable nodejs -y &>>$LOGS_FILE
    VALIDATE $? "disabling nodejs module"

    dnf module enable nodejs:20 -y &>>$LOGS_FILE
    VALIDATE $? "enabling nodejs:20 module"

    dnf install nodejs -y &>>$LOGS_FILE
    VALIDATE $? "installing nodejs"

    npm install &>>$LOGS_FILE
    VALIDATE $? "installing nodejs dependencies"
}
systemd_setup(){

    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service
    VALIDATE $? "copying $app_name service file"
    systemctl daemon-reload &>>$LOGS_FILE
    systemctl enable $app_name &>>$LOGS_FILE
    systemctl start $app_name
    VALIDATE $? "starting $app_name service"
}

print_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME-$START_TIME))
    echo -e "script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOGS_FILE 
}
