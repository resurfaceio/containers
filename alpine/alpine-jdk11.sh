#!/bin/bash
docker build -f alpine-jdk11.dockerfile -t alpine-jdk11:$1 --no-cache .
docker tag alpine-jdk11:$1 resurfaceio/alpine-jdk11:$1
docker push resurfaceio/alpine-jdk11:$1