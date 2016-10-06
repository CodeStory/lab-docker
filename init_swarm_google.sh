#!/bin/bash

set -e

export GOOGLE_PROJECT="code-story-blog"
export GOOGLE_ZONE="europe-west1-d"
export GOOGLE_DISK_SIZE="1000"
export GOOGLE_MACHINE_TYPE="custom-2-8192"

docker-machine create -d google gce-manager
docker-machine create -d google gce-worker1
docker-machine create -d google gce-worker2
docker-machine create -d google gce-worker3

docker $(docker-machine config gce-manager) \
  swarm init \
  --listen-addr $(gcloud compute instances list gce-manager --format='value(networkInterfaces.networkIP)'):2377 \
  --advertise-addr $(gcloud compute instances list gce-manager --format='value(networkInterfaces.networkIP)'):2377

docker $(docker-machine config gce-worker1) \
  swarm join $(docker-machine ip gce-manager):2377 \
  --listen-addr $(gcloud compute instances list gce-worker1 --format='value(networkInterfaces.networkIP)'):2377 \
  --token $(docker $(docker-machine config gce-manager) swarm join-token worker -q)

docker $(docker-machine config gce-worker2) \
  swarm join $(docker-machine ip gce-manager):2377 \
  --listen-addr $(gcloud compute instances list gce-worker2 --format='value(networkInterfaces.networkIP)'):2377 \
  --token $(docker $(docker-machine config gce-manager) swarm join-token worker -q)

docker $(docker-machine config gce-worker3) \
  swarm join $(docker-machine ip gce-manager):2377 \
  --listen-addr $(gcloud compute instances list gce-worker3 --format='value(networkInterfaces.networkIP)'):2377 \
  --token $(docker $(docker-machine config gce-manager) swarm join-token worker -q)

docker $(docker-machine config gce-manager) info
