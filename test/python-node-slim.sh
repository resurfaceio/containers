#!/bin/bash
docker build -f python-node-slim.dockerfile -t python-node-slim:$1 --no-cache .
docker tag python-node-slim:$1 resurfaceio/python-node-slim:$1
docker push resurfaceio/python-node-slim:$1
