#!/bin/bash -x
# Reference: https://github.com/operator-framework/community-operators/blob/master/docs/testing-operators.md
dnf config-manager --add-repo https://cbs.centos.org/repos/paas7-crio-311-candidate/x86_64/os/
echo "gpgcheck=0" >> /etc/yum.repos.d/cbs.centos.org_repos_paas7-crio-311-candidate_x86_64_os_.repo 
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum -y install \
  cri-o \
  dnf-utils \
  git \
  kubectl \
  podman-docker \
  socat
 VERSION="v1.17.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz
# change the /usr/lib/systemd/system/crio.service file instead --seccomp-profile=/etc/crio/seccomp.json
# sed s'/seccomp_profile.*/seccomp_profile = "/etc/crio/seccomp.json"/' -i /etc/crio/crio.conf


# This service doesn't do anything, but it has to be running
sudo systemctl start docker.service

# Tell the minikube we're not using docker for the container engine
touch /etc/containers/nodocker

systemctl enable kubelet.service

systemctl stop swap.target 
systemctl disable swap.target
yum -y install socat

modprobe br_netfilter
sysctl net.bridge.bridge-nf-call-iptables=1

# Test kubectl
kubectl version

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube \
  && mv minikube /usr/local/bin \
  && /usr/local/bin/minikube start \
    --vm-driver=none \
    --extra-config=kubeadm.ignore-preflight-errors=IsDockerSystemdCheck,SystemVerification \
    --network-plugin=cni \
    --enable-default-cni \
    --container-runtime=cri-o \
    --bootstrapper=kubeadm

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
