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
if [ $USERID -ne 0 ]
then
    echo -e "$R Error : only root user can run this script $N" | tee -a $LOGS_FILE
    exit 1
else 
    echo "you are running with root access" | tee -a $LOGS_FILE
fi

echo "please enter rabbitmq password to setup"
read -s RABBITMQ_PASSWD

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e " $2 is ...$G success $N " | tee -a $LOGS_FILE
    else
        echo -e "$2 is $R failed $N" | tee -a $LOGS_FILE
        exit 1
    fi
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "copying rabbitmq.repo"

dnf install rabbitmq-server -y &>>$LOGS_FILE
VALIDATE $? "installing rabbitmq-server"

systemctl enable rabbitmq-server
VALIDATE $? "enabling rabbitmq server"

systemctl start rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "starting rabbitmq server"
 
rabbitmqctl add_user roboshop $RABBITMQ_PASSWD
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))

echo -e "script execution completed successfully, $Y time taken: $TOTAL_TIME $N" | tee -a $LOGS_FILE
