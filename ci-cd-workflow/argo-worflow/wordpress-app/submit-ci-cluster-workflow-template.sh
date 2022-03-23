CurrentClusterPath="$(echo $KUBECONFIG)"
echo $CurrentClusterPath
echo "Creating kubernetes secret for jfrog credentials in argo namespace"
echo "                                                    "
kubectl create secret generic jfrog-config -n argo \
    --from-file=.dockerconfigjson=config.json \
    --type=kubernetes.io/dockerconfigjson
sleep 1
echo "                                                    "

echo "Creating kubernetes secret for px snapshot script "
kubectl create secret generic wordpress-snapshot-script --from-file=./px-snaphost-restore-script/px-snapshot.yaml  --from-file=./px-snaphost-restore-script/create-snapshot.sh -n argo
sleep 1
echo "                                                    "
echo "Creating kubernetes secret for px restore snapshot script "
kubectl create secret generic wordpress-restore-snapshot-script  --from-file=./px-snaphost-restore-script/px-restore-snapshot.yaml  --from-file=./px-snaphost-restore-script/restore-snapshot.sh -n argo
sleep 1
source ../../setup-vars/setup-vars
echo "                                                    "
cat $ClusterKubeConfigFilePath > config
echo "Creating kubernetes secret for application git repo cluster kubeconfig. "
kubectl create secret generic kubernetes-kube-config --from-file=config -n argo
sleep 1
export KUBECONFIG=$ClusterKubeConfigFilePath
echo "                                                    "
mkdir -p $gitRepoNamespace
kubectl get secret git-ssh-key -n $gitRepoNamespace -o jsonpath='{.data.id_rsa}' > ./$gitRepoNamespace/id_rsa.tmp
sleep 1
base64 -d ./$gitRepoNamespace/id_rsa.tmp > ./$gitRepoNamespace/id_rsa
export KUBECONFIG=$CurrentClusterPath
echo $KUBECONFIG
echo "Creating kubernetes secret for application code git server ssh private key"
kubectl create secret generic wordpress-repo-sshkey --from-file=./$gitRepoNamespace/id_rsa -n argo
sleep 3
rm -rf $gitRepoNamespace

#argo cluster-template create ./workflow-templates/clusterworkflowtemplate-for-master.yaml
argo cluster-template create ./workflow-templates/clusterworkflowtemplate-for-dev.yaml
rm config