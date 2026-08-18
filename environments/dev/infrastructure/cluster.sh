#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status during setup
set -e

usage() {
    echo "Usage: $0 [up|down]"
    echo "  up   - Initialize, plan, and apply local AWS infrastructure via Floci."
    echo "  down - Destroy infrastructure, stop Floci, and reclaim local disk space."
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

case "$1" in
    up)
        echo "=== [UP] Deploying Infrastructure to Floci ==="
        
        echo "--> Initializing Terraform..."
        terraform init 
        
        echo "--> Generating execution plan..."
        terraform plan -var="use_floci=true"
        
        echo "--> Applying infrastructure changes..."
        terraform apply -var="use_floci=true" -auto-approve
        
        echo "=== [UP] Deployment complete! ==="
        ;;

    down)
        echo "=== [DOWN] Cleaning Up Infrastructure & Reclaiming Disk Space ==="
        
        # Disable strict exit so teardown completes even if one command returns non-zero
        set +e

        echo "--> Running Terraform Destroy..."
        terraform destroy -var="use_floci=true" -auto-approve

        echo "--> Stopping Floci process/containers..."
        if command -v floci &> /dev/null; then
            floci stop || true
        fi

        # Stop Floci container if running directly via Docker
        if command -v docker &> /dev/null; then
            docker stop $(docker ps -q --filter "ancestor=floci") 2>/dev/null || true
            docker rm -f $(docker ps -a -q --filter "ancestor=floci") 2>/dev/null || true

            echo "--> Reclaiming disk space (pruning unused Docker containers, images & volumes)..."
            docker system prune --volumes -f
        fi

        echo "--> Removing local Terraform state, cached providers, and locks..."
        rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

        echo "--> Reclaiming local AWS CLI & Floci caches..."
        rm -rf ~/.aws/cli/cache
        rm -rf ~/.floci/cache 2>/dev/null || true

        echo "=== [DOWN] Teardown complete. All temporary files and disk space reclaimed! ==="
        ;;

    *)
        usage
        ;;
esac