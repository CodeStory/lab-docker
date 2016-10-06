#!/bin/bash

set -e

docker-machine create -d virtualbox manager
docker-machine create -d virtualbox worker1
docker-machine create -d virtualbox worker2
docker-machine create -d virtualbox worker3

docker $(docker-machine config manager) \
  swarm init \
  --listen-addr $(docker-machine ip manager):2377 \
  --advertise-addr $(docker-machine ip manager):2377

docker $(docker-machine config worker1) \
  swarm join $(docker-machine ip manager):2377 \
  --listen-addr $(docker-machine ip worker1):2377 \
  --token $(docker $(docker-machine config manager) swarm join-token worker -q)

docker $(docker-machine config worker2) \
  swarm join $(docker-machine ip manager):2377 \
  --listen-addr $(docker-machine ip worker2):2377 \
  --token $(docker $(docker-machine config manager) swarm join-token worker -q)

docker $(docker-machine config worker3) \
  swarm join $(docker-machine ip manager):2377 \
  --listen-addr $(docker-machine ip worker3):2377 \
  --token $(docker $(docker-machine config manager) swarm join-token worker -q)

docker $(docker-machine config manager) info
