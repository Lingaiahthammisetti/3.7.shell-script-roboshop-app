#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root access. $N"
    exit 1
else
    echo -e "$G You are super user. $N"
fi

if [ ! -f mongo.repo ]; then
    echo -e "$R mongo.repo file not found in the current directory. $N"
    exit 1
fi

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "Copied mongo repo"

dnf install mongodb-org -y &>> $LOGFILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>> $LOGFILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>> $LOGFILE
VALIDATE $? "Starting MongoDB" 

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOGFILE
VALIDATE $? "Configuring remote server"

systemctl restart mongod &>> $LOGFILE
VALIDATE $? "Restarted MongoDB"

systemctl status mongod &>> $LOGFILE
VALIDATE $? "Checking MongoDB status"

netstat -lntp | grep mongod &>> $LOGFILE
VALIDATE $? "Checking MongoDB Port"