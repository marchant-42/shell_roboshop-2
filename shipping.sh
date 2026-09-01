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
echo "please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

dnf install maven -y
VALIDATE $? "installing maven"

id roboshop &>$LOGS_FILE
if [$? -ne 0 ]
  
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating roboshop system user"
else
    echo -e "roboshop user is $Y already present nothing to do $N"
fi
mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOGS_FILE
VALIDATE $? "downloading shipping zip file"


rm -rf /app/*
unzip /tmp/shipping.zip -d /app
VALIDATE $? "unzipping shipping zip file"
chown -R roboshop:roboshop /app
cd /app

mvn clean package
VALIDATE $? "building shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOGS_FILE
VALIDATE $? "moving and renaming Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOGS_FILE

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Daemon Rload "

systemctl enable shipping &>>$LOGS_FILE
VALIDATE $? "enabling shipping"

systemctl start shipping &>>$LOGS_FILE
VALIDATE $? "starting shipping"

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "install MySQL"

mysql -h mysql.satishdevops.shop -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities'
if [$? -ne 0 ]
then
    mysql -h mysql.satishdevops.shop -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql
    mysql -h mysql.satishdevops.shop -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql 
    mysql -h mysql.satishdevops.shop -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL...$Y SKIPPING $N" 
fi

systemctl  restart shipping &>>$LOGS_FILE
VALIDATE $? "Starting MySQL"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))

echo -e "script execution completed successfully, $Y time taken: $TOTAL_TIME $N" | tee -a $LOGS_FILE