#!/bin/bash
cd /etc/yum.repos.d/
wget https://download.docker.com/linux/centos/docker-ce.repo 
rpm --import https://download.docker.com/linux/centos/gpg

dnf install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm

dnf install docker-ce.x86_64

systemctl disable firewalld
systemctl enable docker
systemctl start docker
usermod -aG docker $USER

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum -y install kubeadm

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube \
  && mv minikube /usr/local/bin \
  && /usr/local/bin/minikube start \
    --vm-driver=none
