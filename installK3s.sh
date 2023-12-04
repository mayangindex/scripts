#!/bin/bash
exec >installK3s.log
echo '#!/bin/bash' >> vars.sh
echo $token >> vars.sh
echo $lbPublicIPAddressName >> vars.sh
sudo apt-get update
sudo snap install helm --classic
sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
export K3S_VERSION="v1.26.10+k3s2" # Do not change!
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} sh -s - --token $token
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
sudo helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
sudo helm upgrade -i rancher rancher-stable/rancher --create-namespace --namespace cattle-system --set hostname=hklsasddsbxkawd.eastus.cloudapp.azure.com
sudo curl -v -o /etc/profile.d/welcomeK3s.sh ${templateBaseUrl}scripts/welcomeK3s.sh
