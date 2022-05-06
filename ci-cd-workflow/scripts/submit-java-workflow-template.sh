echo > ../argo-worflow/java-app/px-snaphost-script/px-restore-snapshot.yaml
echo > ../argo-worflow/java-app/px-snaphost-script/create-snapshot.sh
echo > ../argo-worflow/java-app/px-snaphost-script/restore-snapshot.sh
echo > ../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml
echo > ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
echo > ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml

cp ../argo-worflow/java-app/px-snaphshot-script-template/px-restore-snapshot.yaml ../argo-worflow/java-app/px-snaphost-script/px-restore-snapshot.yaml
cp ../argo-worflow/java-app/px-snaphshot-script-template/create-snapshot.sh   ../argo-worflow/java-app/px-snaphost-script/create-snapshot.sh
cp ../argo-worflow/java-app/px-snaphshot-script-template/restore-snapshot.sh  ../argo-worflow/java-app/px-snaphost-script/restore-snapshot.sh
cp ../argo-worflow/java-app/px-snaphshot-script-template/px-snapshot.yaml  ../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml
cp ../argo-worflow/java-app/workflow-templates/clusterworkflowtemplate-for-dev.yaml   ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
cp ../argo-worflow/java-app/workflow-templates/clusterworkflowtemplate-for-master.yaml   ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml


vCONFIGFILE=../setup-vars/setup-vars
if (kubectl get secret -n argo | grep jfrog-config ) 2>&1 >/dev/null
then
echo "                                            "
else
echo "Creating kubernetes secret for jfrog credentials in argo namespace"
kubectl create secret generic jfrog-config -n argo \
    --from-file=.dockerconfigjson=../config.json \
    --type=kubernetes.io/dockerconfigjson
fi    
sleep 2
echo "                                                    "           
#Fetching main repositoey details
source ${vCONFIGFILE}
PodName="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH get all -n $PX_Application_MainBranch_Namespace | awk 'FNR == 2 {print$1}' | cut -d"/" -f2)"
REPONAME="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH describe pods $PodName -n $PX_Application_MainBranch_Namespace | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}')"
MasterEXTERNALIP="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH get all -n $PX_Application_MainBranch_Namespace | grep  -A1 "EXTERNAL-IP" | awk 'FNR == 2 {print$4}')"
echo "                                                    "
sed -ie "s,XX-namespace-XX,$PX_Application_MainBranch_Namespace,g" ../argo-worflow/java-app/px-snaphost-script/px-restore-snapshot.yaml
sed -ie "s,XX-repo-XX,$REPONAME,g" ../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml
sed -ie "s,XX-namespace-XX,$PX_Application_MainBranch_Namespace,g"  ../argo-worflow/java-app/px-snaphost-script/create-snapshot.sh
sed -ie "s,XX-namespace-XX,$PX_Application_MainBranch_Namespace,g" ../argo-worflow/java-app/px-snaphost-script/restore-snapshot.sh
sed -ie "s,XX-namespace-XX,$PX_Application_MainBranch_Namespace,g" ../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml
sleep 2



echo "Creating kubernetes px snapshot script secret for main branch  "
kubectl create secret generic java-snapshot-script-main-branch --from-file=../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml  --from-file=../argo-worflow/java-app/px-snaphost-script/create-snapshot.sh -n argo
kubectl label secret java-snapshot-script-main-branch app=argo-wokflow-secret -n argo
sleep 2
echo "                                                    "
echo "                                                    "
echo "Creating kubernetes px restore snapshot script secret for main branch "
kubectl create secret generic java-restore-snapshot-script-main-branch  --from-file=../argo-worflow/java-app/px-snaphost-script/px-restore-snapshot.yaml  --from-file=../argo-worflow/java-app/px-snaphost-script/restore-snapshot.sh -n argo
kubectl label secret java-restore-snapshot-script-main-branch app=argo-wokflow-secret -n argo
sleep 2
echo "                                           "
cat $PX_Application_MainBranch_KUBECONF_PATH > config
echo "Creating kubernetes secret for application git repo cluster kubeconfig. "
kubectl create secret generic java-master-branch-cluster-kube-config --from-file=config -n argo
kubectl label secret java-master-branch-cluster-kube-config app=argo-wokflow-secret -n argo
sleep 2
echo "                                                    "
mkdir -p $PX_Application_MainBranch_Namespace
kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH get secret git-ssh-key -n $PX_Application_MainBranch_Namespace -o jsonpath='{.data.id_rsa}' > ./$PX_Application_MainBranch_Namespace/id_rsa.tmp
sleep 2
base64 -d ./$PX_Application_MainBranch_Namespace/id_rsa.tmp > ./$PX_Application_MainBranch_Namespace/id_rsa
echo "Creating kubernetes secret for application code git server ssh private key"
kubectl  create secret generic java-repo-sshkey --from-file=./$PX_Application_MainBranch_Namespace/id_rsa -n argo
kubectl label secret java-repo-sshkey app=argo-wokflow-secret -n argo
sleep 3
rm -rf $PX_Application_MainBranch_Namespace
rm -rf config
#Fetching Dev repository details
source ${vCONFIGFILE}
DevRepoPodName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH get all -n $PX_Application_DevBranch_Namespace | awk 'FNR == 2 {print$1}' | cut -d"/" -f2)"
REPONAME="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH describe pods $DevRepoPodName -n $PX_Application_DevBranch_Namespace | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}')"
DevBranchName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH exec $DevRepoPodName -n $PX_Application_DevBranch_Namespace -- su - git -c "cd repos/$REPONAME && git branch | awk 'FNR == 1 {print$1}' | cut -d '*' -f2")"
DevEXTERNALIP="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH get all -n $PX_Application_DevBranch_Namespace | grep  -A1 "EXTERNAL-IP" | awk 'FNR == 2 {print$4}')"

echo > ../argo-worflow/java-app/px-snaphost-script/px-restore-snapshot.yaml
echo > ../argo-worflow/java-app/px-snaphost-script/create-snapshot.sh
echo > ../argo-worflow/java-app/px-snaphost-script/restore-snapshot.sh
echo > ../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml
cp ../argo-worflow/java-app/px-snaphshot-script-template/px-restore-snapshot.yaml ../argo-worflow/java-app/px-snaphost-script/px-restore-snapshot.yaml
cp ../argo-worflow/java-app/px-snaphshot-script-template/create-snapshot.sh   ../argo-worflow/java-app/px-snaphost-script/create-snapshot.sh
cp ../argo-worflow/java-app/px-snaphshot-script-template/restore-snapshot.sh  ../argo-worflow/java-app/px-snaphost-script/restore-snapshot.sh
cp ../argo-worflow/java-app/px-snaphshot-script-template/px-snapshot.yaml  ../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml
cat $PX_Application_DevBranch_KUBECONF_PATH > config
sleep 5
sed -ie "s,XX-namespace-XX,$PX_Application_DevBranch_Namespace,g" ../argo-worflow/java-app/px-snaphost-script/px-restore-snapshot.yaml
sed -ie "s,XX-repo-XX,$REPONAME,g" ../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml
sed -ie "s,XX-namespace-XX,$PX_Application_DevBranch_Namespace,g"  ../argo-worflow/java-app/px-snaphost-script/create-snapshot.sh
sed -ie "s,XX-namespace-XX,$PX_Application_DevBranch_Namespace,g" ../argo-worflow/java-app/px-snaphost-script/restore-snapshot.sh
sed -ie "s,XX-namespace-XX,$PX_Application_DevBranch_Namespace,g" ../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml

sed -ie "s,XX-java_Docker_Image-XX,$Java_Docker_Image_Dev_Branch,g" ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
sed -ie "s,XX-java_Docker_Image-XX,$Java_Docker_Image_Main_Branch,g" ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml
sed -ie "s,XX-PX_Application_DevBranch-XX,$DevBranchName,g" ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
sed -ie "s,XX-EXTERNALIP-XX,$DevEXTERNALIP,g" ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
sed -ie "s,XX-EXTERNALIP-XX,$MasterEXTERNALIP,g" ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml
sed -ie "s,XX-RepoName-XX,$REPONAME,g" ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
sed -ie "s,XX-RepoName-XX,$REPONAME,g" ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml
sleep 4
echo "Creating kubernetes px snapshot script secret for dev branch  "
kubectl create secret generic java-snapshot-script-dev-branch --from-file=../argo-worflow/java-app/px-snaphost-script/px-snapshot.yaml  --from-file=../argo-worflow/java-app/px-snaphost-script/create-snapshot.sh -n argo
kubectl label secret java-snapshot-script-dev-branch app=argo-wokflow-secret -n argo
sleep 2
echo "                                                    "
echo "                                                    "
echo "Creating kubernetes px restore snapshot script secret for dev branch "
kubectl create secret generic java-restore-snapshot-script-dev-branch  --from-file=../argo-worflow/java-app/px-snaphost-script/px-restore-snapshot.yaml  --from-file=../argo-worflow/java-app/px-snaphost-script/restore-snapshot.sh -n argo
kubectl label secret java-restore-snapshot-script-dev-branch app=argo-wokflow-secret  -n argo
sleep 2
echo "                                           "
kubectl create secret generic java-dev-branch-cluster-kube-config --from-file=config -n argo
kubectl label secret java-dev-branch-cluster-kube-config app=argo-wokflow-secret -n argo

    countYaml=`ls -1 ../argo-worflow/java-app/px-snaphost-script/*.yamle 2>/dev/null | wc -l`
    countScripts=`ls -1 ../argo-worflow/java-app/px-snaphost-script/*.she 2>/dev/null | wc -l`
    if [ "$countYaml" != "0" ] && [ "$countScripts" != "0" ]
    then 
    rm ../argo-worflow/java-app/px-snaphost-script/*.yamle
    rm ../argo-worflow/java-app/px-snaphost-script/*.she
    fi

    countYaml=`ls -1 ../argo-worflow/java-app/workflow-manifests/*.yamle 2>/dev/null | wc -l`
    if [ $countYaml != "0" ]
    then 
    rm ../argo-worflow/java-app/workflow-manifests/*.yamle
    fi
    sleep 2
argo  cluster-template create ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml
argo  cluster-template create ../argo-worflow/java-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
rm config
