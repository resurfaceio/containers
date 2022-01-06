FROM node:slim
RUN apt -y update && apt -y install git python3 python3-pip && pip3 install trino
