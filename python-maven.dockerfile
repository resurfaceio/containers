FROM maven:3.8-jdk-8
RUN apt -y update && apt -y install python3 python3-pip && pip3 install trino