#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
UL="\e[4m"
START_TIME=$(date +%s)

print_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME - $START_TIME))
    echo -e "Script executed successfully, $Y Time taken: $TOTAL_TIME seconds $N"
}

mkdir -p "/var/log/shell_logs"

LOG_FOLDER="/var/log/shell_logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOG_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$R  $2 is ............FAILURE $N"
        exit 1
    else
        echo -e "$G $2 is ............SUCCESS $N"
    fi
}

echo "$0 Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_USER(){
    if [ $USERID -ne 0 ]
    then
        echo -e "ERROR:: $UL You must have sudo access to execute this script $N"
        exit 1 # other than 0
    else 
        echo -e "$G Script name: $0 is executing..... $N"
    fi
}

CHECK_USER

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop user"
else
    echo -e "$Y roboshop user is allready exist $N"
fi


mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "user content download"

rm -rf /app/*
VALIDATE $? "Deleting existing content in /app directory"

cd /app 
VALIDATE $? "redirect to /app directory"

unzip /tmp/user.zip
VALIDATE $? "unziping the content on /app directory"

npm install
VALIDATE $? "npm install.. installing dependencies"

cp /home/ec2-user/roboshop-shell-scripts/06-user.service /etc/systemd/system/user.service
VALIDATE $? "configaring the user service"

systemctl daemon-reload
VALIDATE $? "daemon-reloading.... services"

systemctl enable user
VALIDATE $? "enabling user service"

systemctl start user
VALIDATE $? "starting user service"

print_time
