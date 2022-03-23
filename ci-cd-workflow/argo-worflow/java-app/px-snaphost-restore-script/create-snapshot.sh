#!/bin/bash
set -e -u
set -o pipefail
apt-get update 
apt-get install -y apt-transport-https ca-certificates curl        
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
cp /snapshot-script/px-snapshot.yaml /tmp/px-snapshot-tmp.yaml
sed -i "s,XX-backupname-XX,$(date +%F-%H-%M-%S),g" /tmp/px-snapshot-tmp.yaml
kubectl apply -f /tmp/px-snapshot-tmp.yaml
sleep 5
kubectl get VolumeSnapshot -n springboot-code-main
sleep 5
vBACKUPNAME="$(kubectl get VolumeSnapshot -n springboot-code-main -l=name=snapshot-of-java-app --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')"
echo $vBACKUPNAME;