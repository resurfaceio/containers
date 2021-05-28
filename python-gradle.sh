#!/bin/bash
docker build -f python-gradle.dockerfile -t python-gradle:$1 --no-cache .
docker tag python-gradle:$1 resurfaceio/python-gradle:$1
docker push resurfaceio/python-gradle:$1