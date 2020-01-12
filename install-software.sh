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

curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
  && chmod +x minikube \
  && mv minikube /usr/local/bin \
  && /usr/local/bin/minikube start \
    --vm-driver=none
