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
SCRIPT_DIR=$PWD # script directory where the script is running from
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
dnf install python3 gcc python3-devel -y
VALIDATE $? "installing python3, gcc and python3-devel"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating roboshop system user"
else
    echo -e "roboshop user is $Y already present nothing to do $N"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE
VALIDATE $? "downloading payment zip file"

rm -rf /app/* 
cd /app 
unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "unzipping payment zip file" &>>$LOGS_FILE

cd /app
pip3 install -r requirements.txt &>>$LOGS_FILE

cp $SCRIPT_DIR/payment.service etc/systemd/system/payment.service &>>$LOGS_FILE
VALIDATE $? "copying payment service"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "reloading systemd daemon"

systemctl enable payment &>>$LOGS_FILE
VALIDATE $? "enabling payment service"

systemctl start payment &>>$LOGS_FILE
VALIDATE $? "starting payment service"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "script execution completed successfully, $Y time taken: $TOTAL_TIME $N" | tee -a $LOGS_FILE