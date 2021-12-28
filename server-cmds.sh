#!/usr/bin/env bash

export IMAGE=$1
echo $PASS | docker login -u $USER --password-stdin
docker-compose -f docker-compose.yaml up --detach
echo "success"
