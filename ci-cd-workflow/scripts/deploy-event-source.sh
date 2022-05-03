echo > ../argo-events/manifests/eventSource.yaml
echo > ../argo-events/manifests/eventsource-service.yaml
echo > ../argo-events/manifests/sensor-for-dev-branch.yaml
echo > ../argo-events/manifests/sensor-for-master-branch.yaml
echo > ../argo-events/git-Hook/dev-branch/post-receive
echo > ../argo-events/git-Hook/master-branch/post-receive

vCONFIGFILE=../setup-vars/setup-vars
PS3="Select the option for which you want to deploy Argo-events: "
select opt in java  wordpress ; do

  case $opt in
    java)
    echo "                                          "    
    source ${vCONFIGFILE}
    DevRepoPodName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH get all -n $PX_Application_DevBranch_Namespace | awk 'FNR == 2 {print$1}' | cut -d"/" -f2)"
    REPONAME="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH describe pods $DevRepoPodName -n $PX_Application_DevBranch_Namespace | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}')"
    DevBranchName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH exec $DevRepoPodName -n $PX_Application_DevBranch_Namespace -- su - git -c "cd repos/$REPONAME && git branch | awk 'FNR == 1 {print$1}' | cut -d '*' -f2")"
    GetBranchWithoutSpace="$(echo "$DevBranchName" | sed 's/ //g')"
    cp ../argo-events/manifest-template/eventsource-template.yaml      ../argo-events/manifests/eventSource.yaml
    cp ../argo-events/git-Hook/post-receive-template-dev-branch ../argo-events/git-Hook/dev-branch/post-receive
    cp ../argo-events/git-Hook/post-receive-template-master-branch ../argo-events/git-Hook/master-branch/post-receive
    cp ../argo-events/manifest-template/eventsource-service-template.yaml   ../argo-events/manifests/eventsource-service.yaml
    cp ../argo-events/manifest-template/sensor-template-dev-branch.yaml     ../argo-events/manifests/sensor-for-dev-branch.yaml
    cp ../argo-events/manifest-template/sensor-template-master-branch.yaml  ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-branch-name-XX,$GetBranchWithoutSpace,g"  ../argo-events/git-Hook/dev-branch/post-receive
    sed -ie "s,XX-webhookName-XX,$opt,g" ../argo-events/manifests/eventSource.yaml
    sed -ie "s,XX-branch-name-XX,$GetBranchWithoutSpace,g"    ../argo-events/manifests/eventSource.yaml
    sed -ie "s,XX-serviceName-XX,$opt,g"   ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-branch-name-XX,$GetBranchWithoutSpace,g"    ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-eventSource-XX,$opt,g"   ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-appName-XX,$opt,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-Workflow-template-dev-branch-XX,ci-for-java-app-dev-branch,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-Workflow-template-master-branch-XX,ci-for-java-app-master-branch,g"  ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-branch-name-XX,$GetBranchWithoutSpace,g"    ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-webhookName-XX,$opt,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-appName-XX,$opt,g" ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-webhookName-XX,$opt,g"  ../argo-events/manifests/sensor-for-master-branch.yaml
    countsetupVars=`ls -1 ../argo-events/manifests/*.yamle 2>/dev/null | wc -l`
    if [ $countsetupVars != 0 ]
    then 
    rm ../argo-events/manifests/*.yamle
    fi
    break
    ;;
    wordpress)
    echo "                                          " 
    source ${vCONFIGFILE}
#    echo "Enter the wordpress application git repo dev branch name and make sure it exists there"
#    read devBranch
    DevRepoPodName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH get all -n $PX_Application_DevBranch_Namespace | awk 'FNR == 2 {print$1}' | cut -d"/" -f2)"
    REPONAME="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH describe pods $DevRepoPodName -n $PX_Application_DevBranch_Namespace | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}')"
    DevBranchName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH exec $DevRepoPodName -n $PX_Application_DevBranch_Namespace -- su - git -c "cd repos/$REPONAME && git branch | awk 'FNR == 1 {print$1}' | cut -d '*' -f2")"
    GetBranchWithoutSpace="$(echo "$DevBranchName" | sed 's/ //g')"
    cp ../argo-events/manifest-template/eventsource-template.yaml      ../argo-events/manifests/eventSource.yaml
    cp ../argo-events/git-Hook/post-receive-template-dev-branch ../argo-events/git-Hook/dev-branch/post-receive
    cp ../argo-events/git-Hook/post-receive-template-master-branch ../argo-events/git-Hook/master-branch/post-receive
    cp ../argo-events/manifest-template/eventsource-service-template.yaml   ../argo-events/manifests/eventsource-service.yaml
    cp ../argo-events/manifest-template/sensor-template-dev-branch.yaml     ../argo-events/manifests/sensor-for-dev-branch.yaml
    cp ../argo-events/manifest-template/sensor-template-master-branch.yaml  ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-branch-name-XX,$GetBranchWithoutSpace,g"  ../argo-events/git-Hook/dev-branch/post-receive
    sed -ie "s,XX-webhookName-XX,$opt,g" ../argo-events/manifests/eventSource.yaml
    sed -ie "s,XX-branch-name-XX,$GetBranchWithoutSpace,g"    ../argo-events/manifests/eventSource.yaml
    sed -ie "s,XX-serviceName-XX,$opt,g"   ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-branch-name-XX,$GetBranchWithoutSpace,g"    ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-eventSource-XX,$opt,g"   ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-appName-XX,$opt,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-Workflow-template-dev-branch-XX,ci-for-wordpress-app-dev-branch,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-Workflow-template-master-branch-XX,ci-for-wordpress-app-master-branch,g"  ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-branch-name-XX,$GetBranchWithoutSpace,g"    ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-webhookName-XX,$opt,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-appName-XX,$opt,g" ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-webhookName-XX,$opt,g"  ../argo-events/manifests/sensor-for-master-branch.yaml
    countsetupVars=`ls -1 ../argo-events/manifests/*.yamle 2>/dev/null | wc -l`
    if [ $countsetupVars != 0 ]
    then 
    rm ../argo-events/manifests/*.yamle
    fi
    break
    ;;    
  esac
done
kubectl apply -f ../argo-events/manifests/workflow-service-account.yml
sleep 2
kubectl apply -f ../argo-events/manifests/eventSource.yaml
sleep 2
kubectl apply -f ../argo-events/manifests/eventsource-service.yaml
sleep 2
kubectl apply -f ../argo-events/manifests/sensor-for-dev-branch.yaml
sleep 2
kubectl apply -f ../argo-events/manifests/sensor-for-master-branch.yaml
sleep 2
webhookServiceIP="$(kubectl get svc $opt-webhook-service -n argo-events | awk 'FNR==2{print $4}')"
sed -ie "s,XX-externalIP-XX,$webhookServiceIP,g" ../argo-events/git-Hook/dev-branch/post-receive
sed -ie "s,XX-externalIP-XX,$webhookServiceIP,g" ../argo-events/git-Hook/master-branch/post-receive

REPONAME="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH describe pods $PodName -n $PX_Application_MainBranch_Namespace | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}')"
#Fetching Details of Main repository and uploading post-receive file there.
source ${vCONFIGFILE}
MainRepoPodName="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH get all -n $PX_Application_MainBranch_Namespace | awk 'FNR == 2 {print$1}' | cut -d"/" -f2)"
kubectl cp ../argo-events/git-Hook/master-branch/post-receive  $PX_Application_MainBranch_Namespace/$MainRepoPodName:/home/git/repos/$REPONAME/hooks &&
sleep 3
kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH exec --stdin --tty $MainRepoPodName -n $PX_Application_MainBranch_Namespace -- /bin/bash -c "chmod 777 /home/git/repos/$REPONAME/hooks/post-receive && chown -R git:git /home/git/repos/$REPONAME/hooks/post-receive"
    countsetupDevHooks=`ls -1 ../argo-events/git-Hook/dev-branch/post-receivee 2>/dev/null | wc -l`
    countsetupMasterHooks=`ls -1 ../argo-events/git-Hook/master-branch/post-receivee 2>/dev/null | wc -l`
    if [ "$countsetupDevHooks" != "0" ] && [ "$countsetupMasterHooks" != "0" ]
    then 
    rm ../argo-events/git-Hook/dev-branch/post-receivee
    rm ../argo-events/git-Hook/master-branch/post-receivee
    fi

#Fetching Details of Dev repository and uploading post-receive file there.
DevRepoPodName="$(kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH get all -n $PX_Application_DevBranch_Namespace | awk 'FNR == 2 {print$1}' | cut -d"/" -f2)"
kubectl cp ../argo-events/git-Hook/dev-branch/post-receive  $PX_Application_DevBranch_Namespace/$DevRepoPodName:/home/git/repos/$REPONAME/hooks &&
sleep 3
kubectl --kubeconfig=$PX_Application_DevBranch_KUBECONF_PATH exec --stdin --tty $DevRepoPodName -n $PX_Application_DevBranch_Namespace -- /bin/bash -c "chmod 777 /home/git/repos/$REPONAME/hooks/post-receive && chown -R git:git /home/git/repos/$REPONAME/hooks/post-receive"

