#!/bin/bash

dnf install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm

dnf install docker-ce

systemctl disable firewalld
systemctl enable docker
systemctl start docker
usermod -aG docker $USER
