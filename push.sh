#!/bin/bash

set -e

docker-compose build
docker-compose push
docker save -o images.tar \
  dockerdemos/lab-web \
  dockerdemos/lab-words-dispatcher \
  dockerdemos/lab-words-java \
  mongo-express:0.31.0 \
  mongo:3.3.15
