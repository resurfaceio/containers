FROM ruby:2.6.7
RUN apt -y update && apt -y install python3 python3-pip && pip3 install trino