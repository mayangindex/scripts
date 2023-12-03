#!/bin/bash
exec >installK3s.log
exec 2>&1

sudo apt-get update

sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
sudo adduser staginguser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
sudo echo "staginguser:ArcPassw0rd" | sudo chpasswd

# Injecting environment variables
echo '#!/bin/bash' >> vars.sh
echo $adminUsername:$1 | awk '{print substr($1,2); }' >> vars.sh
echo $appId:$2 | awk '{print substr($1,2); }' >> vars.sh
echo $password:$3 | awk '{print substr($1,2); }' >> vars.sh
echo $tenantId:$4 | awk '{print substr($1,2); }' >> vars.sh
echo $vmName:$5 | awk '{print substr($1,2); }' >> vars.sh
echo $azureLocation:$6 | awk '{print substr($1,2); }' >> vars.sh
echo $templateBaseUrl:$7 | awk '{print substr($1,2); }' >> vars.sh
sed -i '2s/^/export adminUsername=/' vars.sh
sed -i '3s/^/export appId=/' vars.sh
sed -i '4s/^/export password=/' vars.sh
sed -i '5s/^/export tenantId=/' vars.sh
sed -i '6s/^/export vmName=/' vars.sh
sed -i '7s/^/export azureLocation=/' vars.sh
sed -i '8s/^/export templateBaseUrl=/' vars.sh

chmod +x vars.sh 
. ./vars.sh

export K3S_VERSION="v1.26.10+k3s2" # Do not change!

# Creating login message of the day (motd)
sudo curl -v -o /etc/profile.d/welcomeK3s.sh ${templateBaseUrl}scripts/welcomeK3s.sh

# Syncing this script log to 'jumpstart_logs' directory for ease of troubleshooting
sudo -u $adminUsername mkdir -p /home/${adminUsername}/jumpstart_logs
while sleep 1; do sudo -s rsync -a /var/lib/waagent/custom-script/download/0/installK3s.log /home/${adminUsername}/jumpstart_logs/installK3s.log; done &

# Installing Rancher K3s cluster (single control plane)
echo ""
publicIp=$(hostname -i)
sudo mkdir ~/.kube
sudo -u $adminUsername mkdir /home/${adminUsername}/.kube
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --node-external-ip ${publicIp}" INSTALL_K3S_VERSION=v${K3S_VERSION} sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sudo kubectl config rename-context default arck3sdemo --kubeconfig /etc/rancher/k3s/k3s.yaml
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo cp /etc/rancher/k3s/k3s.yaml /home/${adminUsername}/.kube/config
sudo cp /etc/rancher/k3s/k3s.yaml /home/${adminUsername}/.kube/config.staging
sudo chown -R $adminUsername /home/${adminUsername}/.kube/
sudo chown -R staginguser /home/${adminUsername}/.kube/config.staging

# Installing Helm 3
echo ""
sudo snap install helm --classic
IP=$(curl https://ifconfig.io/ip)
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
sleep 120
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm upgrade -i rancher rancher-stable/rancher --create-namespace --namespace cattle-system --set hostname=$IP.nip.io
#
