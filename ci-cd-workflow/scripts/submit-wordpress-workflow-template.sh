echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
echo > ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
echo > ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml

cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/px-restore-snapshot.yaml ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/create-snapshot.sh   ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/restore-snapshot.sh  ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/px-snapshot.yaml  ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
cp ../argo-worflow/wordpress-app/workflow-templates/clusterworkflowtemplate-for-dev.yaml   ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
cp ../argo-worflow/wordpress-app/workflow-templates/clusterworkflowtemplate-for-master.yaml   ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml


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
sed -ie "s,XX-namespace-XX,$PX_Application_MainBranch_Namespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
sed -ie "s,XX-repo-XX,$REPONAME,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
sed -ie "s,XX-namespace-XX,$PX_Application_MainBranch_Namespace,g"  ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
sed -ie "s,XX-namespace-XX,$PX_Application_MainBranch_Namespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
sed -ie "s,XX-namespace-XX,$PX_Application_MainBranch_Namespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
sleep 2



echo "Creating kubernetes px snapshot script secret for main branch  "
kubectl create secret generic wordpress-snapshot-script-main-branch --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh -n argo
sleep 2
echo "                                                    "
echo "                                                    "
echo "Creating kubernetes px restore snapshot script secret for main branch "
kubectl create secret generic wordpress-restore-snapshot-script-main-branch  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh -n argo
sleep 2
echo "                                           "
cat $PX_Application_MainBranch_KUBECONF_PATH > config
echo "Creating kubernetes secret for application git repo cluster kubeconfig. "
kubectl create secret generic wordpress-master-branch-cluster-kube-config --from-file=config -n argo
sleep 2
echo "                                                    "
mkdir -p $PX_Application_MainBranch_Namespace
kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH get secret git-ssh-key -n $PX_Application_MainBranch_Namespace -o jsonpath='{.data.id_rsa}' > ./$PX_Application_MainBranch_Namespace/id_rsa.tmp
sleep 2
base64 -d ./$PX_Application_MainBranch_Namespace/id_rsa.tmp > ./$PX_Application_MainBranch_Namespace/id_rsa
echo "Creating kubernetes secret for application code git server ssh private key"
kubectl  create secret generic wordpress-repo-sshkey --from-file=./$PX_Application_MainBranch_Namespace/id_rsa -n argo
sleep 3
rm -rf $PX_Application_MainBranch_Namespace
rm -rf config
#Fetching Dev repository details
source ${vCONFIGFILE}
DevRepoPodName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH get all -n $PX_Application_DevBranch_Namespace | awk 'FNR == 2 {print$1}' | cut -d"/" -f2)"
REPONAME="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH describe pods $DevRepoPodName -n $PX_Application_DevBranch_Namespace | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}')"
DevBranchName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH exec $DevRepoPodName -n $PX_Application_DevBranch_Namespace -- /bin/bash -c "cd /home/git/repos/$REPONAME && git branch | awk 'FNR == 1 {print$1}' | cut -d '*' -f2")"
DevEXTERNALIP="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH get all -n $PX_Application_DevBranch_Namespace | grep  -A1 "EXTERNAL-IP" | awk 'FNR == 2 {print$4}')"

echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
echo > ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/px-restore-snapshot.yaml ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/create-snapshot.sh   ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/restore-snapshot.sh  ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
cp ../argo-worflow/wordpress-app/px-snaphshot-restore-script-template/px-snapshot.yaml  ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
cat $PX_Application_DevBranch_KUBECONF_PATH > config
sleep 5
sed -ie "s,XX-namespace-XX,$PX_Application_DevBranch_Namespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml
sed -ie "s,XX-repo-XX,$REPONAME,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml
sed -ie "s,XX-namespace-XX,$PX_Application_DevBranch_Namespace,g"  ../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh
sed -ie "s,XX-namespace-XX,$PX_Application_DevBranch_Namespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh
sed -ie "s,XX-namespace-XX,$PX_Application_DevBranch_Namespace,g" ../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml

sed -ie "s,XX-Wordpress_Docker_Image-XX,$Wordpress_Docker_Image_Dev_Branch,g" ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
sed -ie "s,XX-Wordpress_Docker_Image-XX,$Wordpress_Docker_Image_Main_Branch,g" ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml
sed -ie "s,XX-PX_Application_DevBranch-XX,$DevBranchName,g" ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
sed -ie "s,XX-EXTERNALIP-XX,$DevEXTERNALIP,g" ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
sed -ie "s,XX-EXTERNALIP-XX,$MasterEXTERNALIP,g" ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml
sed -ie "s,XX-RepoName-XX,$REPONAME,g" ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
sed -ie "s,XX-RepoName-XX,$REPONAME,g" ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml
sleep 2
echo "Creating kubernetes px snapshot script secret for dev branch  "
kubectl create secret generic wordpress-snapshot-script-dev-branch --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/px-snapshot.yaml  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/create-snapshot.sh -n argo
sleep 2
echo "                                                    "
echo "                                                    "
echo "Creating kubernetes px restore snapshot script secret for dev branch "
kubectl create secret generic wordpress-restore-snapshot-script-dev-branch  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/px-restore-snapshot.yaml  --from-file=../argo-worflow/wordpress-app/px-snaphost-restore-script/restore-snapshot.sh -n argo
sleep 2
echo "                                           "
kubectl create secret generic wordpress-dev-branch-cluster-kube-config --from-file=config -n argo

    countYaml=`ls -1 ../argo-worflow/wordpress-app/px-snaphost-restore-script/*.yamle 2>/dev/null | wc -l`
    countScripts=`ls -1 ../argo-worflow/wordpress-app/px-snaphost-restore-script/*.she 2>/dev/null | wc -l`
    if [ "$countYaml" != "0" ] && [ "$countScripts" != "0" ]
    then 
    rm ../argo-worflow/wordpress-app/px-snaphost-restore-script/*.yamle
    rm ../argo-worflow/wordpress-app/px-snaphost-restore-script/*.she
    fi

    countYaml=`ls -1 ../argo-worflow/wordpress-app/workflow-manifests/*.yamle 2>/dev/null | wc -l`
    if [ $countYaml != "0" ]
    then 
    rm ../argo-worflow/wordpress-app/workflow-manifests/*.yamle
    fi
    sleep 2
argo  cluster-template create ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-master.yaml
argo  cluster-template create ../argo-worflow/wordpress-app/workflow-manifests/clusterworkflowtemplate-for-dev.yaml
rm config
