#!/bin/bash
exec >installK3s.log
exec 2>&1

sudo apt-get update


# Injecting environment variables
export adminUsername=$1
export token=$2
export location=$3
export fqdn=$4
export templateBaseUrl=$5
export K3S_VERSION="v1.26.10+k3s2" # Do not change!
 # Creating login message of the day (motd)
sudo curl -v -o /etc/profile.d/welcomeK3s.sh ${templateBaseUrl}/welcomeK3s.sh
curl -sfL https://get.rke2.io | INSTALL_K3S_VERSION=v1.25.15+rke2r1 sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
export KUBECONFIG=/etc/rancher/rke2/rke2/rke2.yaml

echo 'PATH=$PATH:/usr/local/bin' >> /etc/profile && echo 'PATH=$PATH:{{rke_dir}}/rke2/bin' >> /etc/profile && source /etc/profile
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
sleep 60
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm upgrade -i rancher rancher-stable/rancher --create-namespace --namespace cattle-system --set hostname=$fqdn