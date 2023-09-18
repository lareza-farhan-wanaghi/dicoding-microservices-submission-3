#!/bin/bash

# Build Docker image
docker build -t ghcr.io/lareza-farhan-wanaghi/order-service:latest .

# Log in to GitHub Container Registry
echo $GH_PACKAGES_TOKEN | docker login ghcr.io -u lareza-farhan-wanaghi --password-stdin

# Push Docker image to GitHub Container Registry
docker push ghcr.io/lareza-farhan-wanaghi/order-service:latest
