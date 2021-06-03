#!/bin/bash
docker build -f python-node.dockerfile -t python-node:$1 --no-cache .
docker tag python-node:$1 resurfaceio/python-node:$1
docker push resurfaceio/python-node:$1