CurrentClusterPath="$(echo $KUBECONFIG)"
echo $CurrentClusterPath
echo "Creating kubernetes secret for jfrog credentials in argo namespace"
echo "                                                    "
kubectl create secret generic jfrog-config -n argo \
    --from-file=.dockerconfigjson=config.json \
    --type=kubernetes.io/dockerconfigjson

echo "                                                    "

echo "Creating kubernetes secret for px snapshot script "
kubectl create secret generic snapshot-script --from-file=./px-snaphost-restore-script/px-snapshot.yaml  --from-file=./px-snaphost-restore-script/create-snapshot.sh -n argo

echo "Creating kubernetes secret for px restore snapshot script "
kubectl create secret generic restore-snapshot-script  --from-file=./px-snaphost-restore-script/px-restore-snapshot.yaml  --from-file=./px-snaphost-restore-script/restore-snapshot.sh -n argo

source ../../setup-vars/setup-vars
echo "                                                    "
cat $ClusterKubeConfigFilePathAppCode > config
echo "Creating kubernetes secret for application git repo cluster kubeconfig in argo namespace "
kubectl create secret generic kubernetes-kube-config --from-file=config -n argo
export KUBECONFIG=$ClusterKubeConfigFilePathAppCode
echo "                                                    "
mkdir $gitRepoNamespace
kubectl get secret git-ssh-key -n $gitRepoNamespace -o jsonpath='{.data.id_rsa}' > ./$gitRepoNamespace/id_rsa.tmp
base64 -d ./$gitRepoNamespace/id_rsa.tmp > ./$gitRepoNamespace/id_rsa
export KUBECONFIG=$CurrentClusterPath
echo $KUBECONFIG
echo "Creating kubernetes secret for application code git server ssh private key"
kubectl create secret generic repo-sshkey --from-file=./$gitRepoNamespace/id_rsa -n argo
sleep 3
rm -rf $gitRepoNamespace

argo cluster-template create ./workflow-templates/clusterworkflowtemplate-for-master.yaml
argo cluster-template create ./workflow-templates/clusterworkflowtemplate-for-dev.yaml
rm config