#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Help message
usage() {
    echo "Usage: $0 [up|down]"
    echo "  up   - Initialize, plan, and apply the local Minikube cluster infrastructure."
    echo "  down - Safely destroy, un-track state, and force-purge the Minikube cluster."
    exit 1
}

# Ensure an argument was passed
if [ -z "$1" ]; then
    usage
fi

case "$1" in
    up)
        echo "=== [UP] Starting Local Minikube Infrastructure ==="
        
        echo "--> Initializing Terraform..."
        terraform init --upgrade
        
        echo "--> Generating execution plan..."
        terraform plan
        
        echo "--> Applying infrastructure changes..."
        terraform apply -auto-approve
        
        echo "=== [UP] Infrastructure is fully deployed! ==="
        ;;

    down)
        echo "=== [DOWN] Tearing Down Local Infrastructure ==="
        
        # Using || true ensures the script keeps moving even if Terraform has nothing to destroy
        echo "--> Running terraform destroy..."
        terraform destroy -auto-approve || true
        
        echo "--> Removing resources from Terraform state tracking..."
        terraform state rm \
          helm_release.argocd \
          kubectl_manifest.argocd_root_application \
          kubernetes_namespace.argocd \
          kubernetes_persistent_volume.grafana_pv \
          kubernetes_persistent_volume.prometheus_pv \
          minikube_cluster.my_cluster || true
        
        echo "--> Forcing Minikube cluster deletion..."
        minikube delete -p minikube || true
        
        echo "--> Cleaning up local state and lock files..."
        rm -f terraform.tfstate terraform.tfstate.backup
        rm -rf .terraform .terraform.lock.hcl
        
        echo "=== [DOWN] Teardown complete. Environment is completely clean! ==="
        ;;

    *)
        usage
        ;;
esac