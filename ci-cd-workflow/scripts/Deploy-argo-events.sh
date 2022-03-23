echo > ../argo-events/manifests/eventSource.yaml
echo > ../argo-events/manifests/eventsource-service.yaml
echo > ../argo-events/manifests/sensor-for-dev-branch.yaml
echo > ../argo-events/manifests/sensor-for-master-branch.yaml
echo > ../argo-events/git-Hook/post-receive

PS3="Select the option for which you want to deploy Argo-events: "
select opt in java  wordpress ; do

  case $opt in
    java)
    echo "                                          "    
    echo "Enter the workflow template details for java app"
    echo "Workflow template for dev branch: "
    read  workflowTemplateDev
    echo "                                          "
    echo "Workflow template for master branch: "
    read workflowTemplateMaster
    echo "                                          "
    echo "Enter the java application git repo dev branch name and make sure it exit there"
    read devBranch
    cp ../argo-events/git-Hook/post-receive-template ../argo-events/git-Hook/post-receive
    cp ../argo-events/manifest-template/eventsource-template.yaml      ../argo-events/manifests/eventSource.yaml
    cp ../argo-events/manifest-template/eventsource-service-template.yaml   ../argo-events/manifests/eventsource-service.yaml
    cp ../argo-events/manifest-template/sensor-template-dev-branch.yaml     ../argo-events/manifests/sensor-for-dev-branch.yaml
    cp ../argo-events/manifest-template/sensor-template-master-branch.yaml  ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-branch-name-XX,$devBranch,g"  ../argo-events/git-Hook/post-receive
    sed -ie "s,XX-webhookName-XX,$opt,g" ../argo-events/manifests/eventSource.yaml
    sed -ie "s,XX-branch-name-XX,$devBranch,g"    ../argo-events/manifests/eventSource.yaml
    sed -ie "s,XX-serviceName-XX,$opt,g"   ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-branch-name-XX,$devBranch,g"    ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-eventSource-XX,$opt,g"   ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-appName-XX,$opt,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-Workflow-template-dev-branch-XX,$workflowTemplateDev,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-Workflow-template-master-branch-XX,$workflowTemplateMaster,g"  ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-branch-name-XX,$devBranch,g"    ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-webhookName-XX,$opt,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-appName-XX,$opt,g" ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-webhookName-XX,$opt,g"  ../argo-events/manifests/sensor-for-master-branch.yaml
    sleep 1
    countsetupVars=`ls -1 ../argo-events/manifests/*.yamle 2>/dev/null | wc -l`
    if [ $countsetupVars != 0 ]
    then 
    rm ../argo-events/manifests/*.yamle
    fi
    break
    ;;
    wordpress)
    echo "                                          "    
    echo "Enter the workflow template details for wordpress app"
    echo "Workflow template for dev branch: "
    read  workflowTemplateDev
    echo "                                          "
    echo "Workflow template for master branch: "
    read workflowTemplateMaster
    echo "                                          "
    echo "Enter the wordpress application git repo dev branch name and make sure it exit there"
    read devBranch
    cp ../argo-events/git-Hook/post-receive-template ../argo-events/git-Hook/post-receive
    cp ../argo-events/manifest-template/eventsource-template.yaml      ../argo-events/manifests/eventSource.yaml
    cp ../argo-events/manifest-template/eventsource-service-template.yaml   ../argo-events/manifests/eventsource-service.yaml
    cp ../argo-events/manifest-template/sensor-template-dev-branch.yaml     ../argo-events/manifests/sensor-for-dev-branch.yaml
    cp ../argo-events/manifest-template/sensor-template-master-branch.yaml  ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-branch-name-XX,$devBranch,g"  ../argo-events/git-Hook/post-receive
    sed -ie "s,XX-webhookName-XX,$opt,g" ../argo-events/manifests/eventSource.yaml
    sed -ie "s,XX-branch-name-XX,$devBranch,g"    ../argo-events/manifests/eventSource.yaml
    sed -ie "s,XX-serviceName-XX,$opt,g"   ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-branch-name-XX,$devBranch,g"    ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-eventSource-XX,$opt,g"   ../argo-events/manifests/eventsource-service.yaml
    sed -ie "s,XX-appName-XX,$opt,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-Workflow-template-dev-branch-XX,$workflowTemplateDev,g"  ../argo-events/manifests/sensor-for-dev-branch.yaml
    sed -ie "s,XX-Workflow-template-master-branch-XX,$workflowTemplateMaster,g"  ../argo-events/manifests/sensor-for-master-branch.yaml
    sed -ie "s,XX-branch-name-XX,$devBranch,g"    ../argo-events/manifests/sensor-for-dev-branch.yaml
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
kubectl apply -f ../argo-events/manifests/eventSource.yaml
sleep 1
kubectl apply -f ../argo-events/manifests/eventsource-service.yaml
sleep 1
kubectl apply -f ../argo-events/manifests/sensor-for-dev-branch.yaml
sleep 1
kubectl apply -f ../argo-events/manifests/sensor-for-master-branch.yaml
sleep 1
webhookServiceIP="$(kubectl get svc $opt-webhook-service -n argo-events | awk 'FNR==2{print $4}')"
echo $webhookServiceIP
sed -ie "s,XX-externalIP-XX,$webhookServiceIP,g" ../argo-events/git-Hook/post-receive
source ../setup-vars/setup-vars
export KUBECONFIG=$ClusterKubeConfigFilePath
Vpodname="$(kubectl get pod -n $gitRepoNamespace | awk 'FNR==2{print $1}')"
echo $Vpodname
kubectl cp ../argo-events/git-Hook/post-receive $gitRepoNamespace/$Vpodname:/home/git/repos/$gitRepoName/hooks && 
sleep 1
kubectl exec --stdin --tty $Vpodname -n $gitRepoNamespace -- /bin/bash -c "chmod 777 /home/git/repos/$gitRepoName/hooks/post-receive"






















#source ../setup-vars/setup-vars
#export KUBECONFIG=$ClusterKubeConfigFile
#Vpodname="$(kubectl get pod -n $gitRepoNamespace | awk 'FNR==2{print $1}')"
#echo $Vpodname
#kubectl cp ./git-Hook/post-receive $gitRepoNamespace/$Vpodname:/home/git/repos/$gitRepoName/hooks && 
#kubectl exec --stdin --tty $Vpodname -n $gitRepoNamespace -- /bin/bash -c "chmod 777 /home/git/repos/$gitRepoName/hooks/post-receive"

