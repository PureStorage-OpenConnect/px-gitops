echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml

cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/px-restore-snapshot.yaml ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/create-snapshot.sh   ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/restore-snapshot.sh  ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/px-snapshot.yaml  ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml



CurrentClusterPath="$(echo $KUBECONFIG)"
#echo $CurrentClusterPath
echo "Creating kubernetes secret for jfrog credentials in argo namespace"
kubectl create secret generic jfrog-config -n argo \
    --from-file=.dockerconfigjson=../config.json \
    --type=kubernetes.io/dockerconfigjson
sleep 2
echo "                                                    "           
source ../setup-vars/setup-vars
echo "                                                    "
sed -ie "s,XX-namespace-XX,$gitRepoNamespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
sed -ie "s,XX-repo-XX,$gitRepoName,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
sed -ie "s,XX-namespace-XX,$gitRepoNamespace,g"  ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
sed -ie "s,XX-namespace-XX,$gitRepoNamespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
sed -ie "s,XX-namespace-XX,$gitRepoNamespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
sleep 2

    countYaml=`ls -1 ../argo-worflow/wordpress-app/px-snaphost-restore-script/*.yamle 2>/dev/null | wc -l`
    countScripts=`ls -1 ../argo-worflow/wordpress-app/px-snaphost-restore-script/*.she 2>/dev/null | wc -l`
    if [ "$countYaml" != "0" ] && [ "$countScripts" != "0" ]
    then 
    rm ../argo-worflow/wordpress-app/px-snaphost-restore-script/*.yamle
    rm ../argo-worflow/wordpress-app/px-snaphost-restore-script/*.she
    fi
    sleep 2


echo "Creating kubernetes secret for px snapshot script "
kubectl create secret generic wordpress-snapshot-script --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh -n argo
sleep 2
echo "                                                    "
echo "                                                    "
echo "Creating kubernetes secret for px restore snapshot script "
kubectl create secret generic wordpress-restore-snapshot-script  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh -n argo
sleep 2

cat $ClusterKubeConfigFilePath > config
echo "Creating kubernetes secret for application git repo cluster kubeconfig. "
kubectl create secret generic kubernetes-kube-config --from-file=config -n argo
sleep 2
#export KUBECONFIG=$ClusterKubeConfigFilePath
echo "                                                    "
mkdir -p $gitRepoNamespace
kubectl get secret git-ssh-key -n $gitRepoNamespace -o jsonpath='{.data.id_rsa}' > ./$gitRepoNamespace/id_rsa.tmp
sleep 2
base64 -d ./$gitRepoNamespace/id_rsa.tmp > ./$gitRepoNamespace/id_rsa
export KUBECONFIG=$CurrentClusterPath
#echo $KUBECONFIG
echo "Creating kubernetes secret for application code git server ssh private key"
kubectl create secret generic wordpress-repo-sshkey --from-file=./$gitRepoNamespace/id_rsa -n argo
sleep 3
rm -rf $gitRepoNamespace

argo cluster-template create ../argo-worflow/wordpress-app/workflow-templates/clusterworkflowtemplate-for-master.yaml
argo cluster-template create ../argo-worflow/wordpress-app/workflow-templates/clusterworkflowtemplate-for-dev.yaml
rm config
