#!/bin/bash
exec >installK3s.log
exec 2>&1

sudo apt-get update


# Injecting environment variables
echo '#!/bin/bash' >> vars.sh
echo $adminUsername:$1 | awk '{print substr($1,2); }' >> vars.sh
echo $token:$2 | awk '{print substr($1,2); }' >> vars.sh
echo $location:$3 | awk '{print substr($1,2); }' >> vars.sh
echo $fqdn:$4 | awk '{print substr($1,2); }' >> vars.sh
echo $templateBaseUrl:$5 | awk '{print substr($1,2); }' >> vars.sh
sed -i '2s/^/export adminUsername=/' vars.sh
sed -i '3s/^/export token=/' vars.sh
sed -i '4s/^/export location=/' vars.sh
sed -i '5s/^/export fqdn=/' vars.sh
sed -i '6s/^/export templateBaseUrl=/' vars.sh
export K3S_VERSION="v1.26.10+k3s2" # Do not change!
chmod +x vars.sh
. ./vars.sh
 # Creating login message of the day (motd)
sudo curl -v -o /etc/profile.d/welcomeK3s.sh ${templateBaseUrl}scripts/welcomeK3s.sh
curl -sfL https://get.rke2.io | INSTALL_K3S_VERSION=v1.25.15+rke2r1 sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
export KUBECONFIG=/etc/rancher/rke2/rke2/rke2.yaml

echo 'PATH=$PATH:/usr/local/bin' >> /etc/profile && echo 'PATH=$PATH:{{rke_dir}}/rke2/bin' >> /etc/profile && source /etc/profile
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
sleep 60
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm upgrade -i rancher rancher-stable/rancher --create-namespace --namespace cattle-system --set hostname=$fqdn