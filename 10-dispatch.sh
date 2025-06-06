#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
UL="\e[4m"

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

dnf install golang -y &>>$LOG_FILE_NAME
VALIDATE $? "installing golang"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop user"
else
    echo -e "$Y roboshop cart is allready exist $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip
VALIDATE $? "dispatch  content download"

rm -rf /app/*
VALIDATE $? "Deleting existing content in /app directory"

cd /app 
VALIDATE $? "redirect to /app directory"

unzip /tmp/dispatch.zip
VALIDATE $? "unziping the content on /app directory"

go mod init dispatch
VALIDATE $? "Running go mod init dispatch"
go get 
VALIDATE $? "Running go get"
go build
VALIDATE $? "Running go build"


cp /home/ec2-user/roboshop-shell-scripts/10-dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "configaring the dispatch service"

systemctl daemon-reload
VALIDATE $? "daemon-reloading.... services"

systemctl enable dispatch
VALIDATE $? "enabling dispatch service"

systemctl start dispatch
VALIDATE $? "starting dispatch service"

print_time