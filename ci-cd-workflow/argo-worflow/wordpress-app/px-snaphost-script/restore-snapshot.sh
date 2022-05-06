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
Noresource="No resources found in wordpress-dev namespace."
getSnapshotRestore="$(kubectl get VolumeSnapshotRestore -n wordpress-dev 2>&1)"
if [[ "$Noresource" == "$getSnapshotRestore" ]]; then
    sed -i "s,XX-restorename-XX,1,g" /tmp/px-restore-snapshot-tmp.yaml
    vSNAPSHOT="$(kubectl get VolumeSnapshot -n wordpress-dev -l=name=snapshot-of-wordpress-app --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')"
    echo $vSNAPSHOT
    sed -i "s,XX-snapshot-name-XX,$vSNAPSHOT,g" /tmp/px-restore-snapshot-tmp.yaml
    cat /tmp/px-restore-snapshot-tmp.yaml
    kubectl apply -f /tmp/px-restore-snapshot-tmp.yaml
    sleep 5
    kubectl describe -f /tmp/px-restore-snapshot-tmp.yaml
else
    vSnapshotRestore="$(kubectl get VolumeSnapshotRestore -n wordpress-dev -l=name=restore-of-wordpress-app  --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')"
    SnapshotRestoreID="$(echo $vSnapshotRestore | cut -d"-" -f4)"
    echo $SnapshotRestoreID;
    NewID="$(expr $SnapshotRestoreID + 1)"
    echo $NewID
    sed -i "s,XX-restorename-XX,$NewID,g" /tmp/px-restore-snapshot-tmp.yaml
    vSNAPSHOT="$(kubectl get VolumeSnapshot -n wordpress-dev -l=name=snapshot-of-wordpress-app --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')"
    echo $vSNAPSHOT
    sed -i "s,XX-snapshot-name-XX,$vSNAPSHOT,g" /tmp/px-restore-snapshot-tmp.yaml
    cat /tmp/px-restore-snapshot-tmp.yaml
    kubectl apply -f /tmp/px-restore-snapshot-tmp.yaml
    sleep 5
    kubectl describe -f /tmp/px-restore-snapshot-tmp.yaml
    kubectl get VolumeSnapshotRestore -n wordpress-main
fi        
