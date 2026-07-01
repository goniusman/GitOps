#!/usr/bin/env bash

minikube stop


minikube delete


minikube delete

docker system prune -af

docker volume prune -f



