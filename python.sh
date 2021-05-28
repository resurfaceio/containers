#!/bin/bash
docker build -f python.dockerfile -t python:$1 --no-cache .
docker tag python:$1 resurfaceio/python:$1
docker push resurfaceio/python:$1