#!/bin/bash

KF_VERSION=v1.8.0-rc.1

helpFunction()
{
    echo ""
    echo "Usage: install.sh [OPTIONAL -v]"
    echo "-v    vanilla kubeflow"
    exit 1 # Exit script after printing help
}

while getopts ":v" option; do
    case $option in
        v ) vanilla_kubeflow="vanilla_kubeflow" ;;
        ? ) helpFunction ;;
    esac
done

# Download kubeflow manifests
wget https://github.com/kubeflow/manifests/archive/refs/tags/"$KF_VERSION".tar.gz
mkdir manifests
tar -xvf "$KF_VERSION".tar.gz -C manifests --strip-components=1

# Remove downloaded tar file
rm "$KF_VERSION".tar.gz

if [ -z "$vanilla_kubeflow"  ]
then
    echo "Using nutanix object store"
    # Patch kubeflow pipelines
    cp overlays/pipeline/pipeline-kustomization.yaml manifests/apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user/kustomization.yaml
    mkdir -p manifests/apps/pipeline/upstream/env/ntnx
    cp -r overlays/pipeline/ntnx manifests/apps/pipeline/upstream/env
fi

# Install kubeflow
while ! kustomize build manifests/example  | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

# Remove kubeflow manifests
rm -rf manifests