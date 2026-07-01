#!/usr/bin/env bash

set -e

echo "Starting Minikube..."

minikube start \
    --driver=docker \
    --cpus=4 \
    --memory=11963 \
    --disk-size=30g \
    --kubernetes-version=stable

echo "Enabling addons..."

minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable storage-provisioner
minikube addons enable default-storageclass

echo "Waiting for node..."

kubectl wait \
    --for=condition=Ready node/minikube \
    --timeout=300s

kubectl get nodes

kubectl get storageclass

echo "Minikube Ready!"