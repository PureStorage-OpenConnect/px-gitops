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
Noresource="No resources found in wordpress-dev namespace."
getSnapshot="$(kubectl get VolumeSnapshot -n wordpress-dev 2>&1)"
if [[ "$Noresource" == "$getSnapshot" ]]; then
  sed -i "s,XX-backupname-XX,1,g" /tmp/px-snapshot-tmp.yaml
  kubectl apply -f /tmp/px-snapshot-tmp.yaml
else
  vSNAPSHOT="$(kubectl get VolumeSnapshot -n wordpress-dev -l=name=snapshot-of-wordpress-app --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')"
  snapshotID="$(echo $vSNAPSHOT | cut -d"-" -f4)"
  echo $snapshotID;
  NewID="$(expr $snapshotID + 1)"
  echo $NewID
  sed -i "s,XX-backupname-XX,$NewID,g" /tmp/px-snapshot-tmp.yaml
  kubectl apply -f /tmp/px-snapshot-tmp.yaml
fi
sleep 5
kubectl get VolumeSnapshot -n wordpress-dev
