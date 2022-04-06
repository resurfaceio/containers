#!/bin/bash
docker build -f alpine-jdk11.dockerfile -t alpine-jdk11:$1 --no-cache .