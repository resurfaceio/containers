FROM python:3.7
RUN apt -y update && apt -y install python3-pip && pip3 install trino