#!/bin/bash
docker buildx build --platform linux/amd64,linux/arm64 -f alpine-jdk11.dockerfile -t resurfaceio/alpine-jdk11:$1 --no-cache --push .