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
    echo -e "$R Error : only root cart can run this script $N" | tee -a $LOGS_FILE
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

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system cart" roboshop
    VALIDATE $? "creating roboshop system cart"
else
    echo -e "roboshop cart is $Y already present nothing to do $N"
fi


mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
VALIDATE $? "downloading cart zip file"

rm -rf /app/* &>>$LOGS_FILE
cd /app
unzip /tmp/cart.zip &>>$LOGS_FILE
VALIDATE $? "unzipping cart zip file"
 
npm install &>>$LOGS_FILE
VALIDATE $? "installing nodejs dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copying cart service file"

systemctl daemon-reload &>>$LOGS_FILE
systemctl enable cart &>>$LOGS_FILE
systemctl start cart
VALIDATE $? "starting cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME-$START_TIME))

echo -e "script execution completed successfully, $Y time taken: $TOTAL_TIME $N" | tee -a $LOGS_FILE