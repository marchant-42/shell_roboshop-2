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
print_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME-$START_TIME))
    echo -e "script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOGS_FILE 
}