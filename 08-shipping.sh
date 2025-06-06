#!/bin/bash

START_TIME=$(date +%s)
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

dnf install maven -y &>>$LOG_FILE_NAME
VALIDATE $? "installing maven"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "shipping content download"

rm -rf /app/*
VALIDATE $? "Deleting existing content in /app directory"

cd /app 
VALIDATE $? "redirect to /app directory"

unzip /tmp/shipping.zip
VALIDATE $? "unziping the content on /app directory"

mvn clean package
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Moving and renaming Jar file"

cp /home/ec2-user/roboshop-shell-scripts/08-shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "configaring the shipping service"

systemctl enable shipping 
VALIDATE $? "enabling shipping service"

systemctl start shipping
VALIDATE $? "starting shipping service"

# preparing mysql schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "installing MYSQL"

mysql -h 172.31.23.169 -u root -pRoboShop@1 -e 'use cities' &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    mysql -h 172.31.23.169 -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE_NAME
    mysql -h 172.31.23.169 -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE_NAME
    mysql -h 172.31.23.169 -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE_NAME
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi


systemctl restart shipping &>>$LOG_FILE_NAME
VALIDATE $? "restart shipping"

print_time
