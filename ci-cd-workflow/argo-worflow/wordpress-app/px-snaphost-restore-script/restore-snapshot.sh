#!/bin/bash
set -e -u
set -o pipefail
apt-get update 
apt-get install -y apt-transport-https ca-certificates curl        
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
cp /restore-snapshot-script/px-restore-snapshot.yaml /tmp/px-restore-snapshot-tmp.yaml
vSNAPSHOT="$(kubectl get VolumeSnapshot -n springboot-code-main -l=name=snapshot-of-wordpress-app --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')"
echo $vSNAPSHOT
sed -i "s,XX-restorename-XX,$(date +%F-%H-%M-%S),g" /tmp/px-restore-snapshot-tmp.yaml
sed -i "s,XX-snapshot-name-XX,$vSNAPSHOT,g" /tmp/px-restore-snapshot-tmp.yaml
cat /tmp/px-restore-snapshot-tmp.yaml
kubectl apply -f /tmp/px-restore-snapshot-tmp.yaml
sleep 5
kubectl describe -f /tmp/px-restore-snapshot-tmp.yaml