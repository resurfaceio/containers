#!/bin/bash
docker build -f python-tomcat8.dockerfile -t python-tomcat8:$1 --no-cache .
docker tag python-tomcat8:$1 resurfaceio/python-tomcat8:$1
docker push resurfaceio/python-tomcat8:$1