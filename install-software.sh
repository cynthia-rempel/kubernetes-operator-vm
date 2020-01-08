#!/bin/bash -x
# Reference: https://github.com/operator-framework/community-operators/blob/master/docs/testing-operators.md

yum -y install \
  git \
  podman-docker

# Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# Test kubectl
kubectl version

git clone https://github.com/operator-framework/operator-marketplace.git
git clone https://github.com/operator-framework/operator-courier.git
git clone https://github.com/operator-framework/operator-lifecycle-manager.git

pip3 install operator-courier

# Get a Kubernetes cluster
minikube start

# Install OLM
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.13.0/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.13.0/olm.yaml

# Install the Operator Marketplace
kubectl apply -f operator-marketplace/deploy/upstream/

# Create the OperatorSource
kubectl apply -f operator-source.yaml
kubectl get operatorsource johndoe-operators -n marketplace
kubectl get catalogsource -n marketplace

# View Available Operators
kubectl get opsrc johndoe-operators -o=custom-columns=NAME:.metadata.name,PACKAGES:.status.packages -n marketplace

# Create an OperatorGroup
kubectl apply -f operator-group.yaml

# Verify Operator health
kubectl get clusterserviceversion -n marketplace
kubectl get deployment -n marketplace

# Testing with scorecard
operator-sdk scorecard \
  --olm-deployed \
  --crds-dir my-operator/ \
  --csv-path my-operator/my-operator.v1.0.0.clusterserviceversion.yaml
