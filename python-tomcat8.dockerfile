FROM tomcat:8-jdk8
RUN apt -y update && apt -y install python3 python3-pip && pip3 install trino