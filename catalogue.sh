#!/bin/bash

source ./common_script.sh
app_name="catalogue"

check_root
app_setup
nodejs_setup
systemd_setup

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
