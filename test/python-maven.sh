#!/bin/bash
docker build -f python-maven.dockerfile -t python-maven:$1 --no-cache .
docker tag python-maven:$1 resurfaceio/python-maven:$1
docker push resurfaceio/python-maven:$1