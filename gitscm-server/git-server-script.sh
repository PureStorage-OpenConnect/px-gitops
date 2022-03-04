#!/bin/bash
set -e -u
set -o pipefail

echo > ./overlays/development/add-repo-tempfile.yaml
echo > ./overlays/development/add-volume-and-volumemount-tempfile.yaml
echo > ./base/git-server-tempfile.yaml
cp ./base/git-server.yaml ./base/git-server-tempfile.yaml


echo "                                                           "
echo "Enter namespace in which you want to deploy"
read namespace
sed -i "s,XX-label-XX,$namespace,g" ./base/git-server-tempfile.yaml
kubectl create ns $namespace
kubectl label namespaces $namespace app=git-server-for-$namespace include-in-backup=yes type=git-server
echo "                                                           "

echo "Creating kubernetes secret for jfrog artifactory config"
kubectl create secret generic regcred -n $namespace \
    --from-file=.dockerconfigjson=config.json \
    --type=kubernetes.io/dockerconfigjson


ssh-keygen -q -t rsa -m PEM -N "" -f id_rsa
echo "                                                           "
kubectl create secret generic git-ssh-key --from-file=$PWD/id_rsa --from-file=$PWD/id_rsa.pub -n $namespace
kubectl label secret git-ssh-key -n $namespace  app=git-server-for-$namespace include-in-backup=yes type=git-server
echo "                                                           "
mkdir $namespace && mv id_rsa id_rsa.pub ./$namespace
echo "                                                           "
cp ./scripts/mirror-git-repo-template.sh ./scripts/mirror-git-repo.sh
echo "Enter the existing git repo url to want to mirror "
read url
echo "                                                           "
echo "Enter the repo name with suffix '.git'"
read repo
sed -i "s,XX-url-XX,$url,g" ./scripts/mirror-git-repo.sh
sed -i "s,XX-repo-XX,$repo,g" ./scripts/mirror-git-repo.sh
kubectl create secret generic deployment --from-file=./scripts/deploy.sh  -n $namespace
kubectl label secret deployment -n $namespace  app=git-server-for-$namespace include-in-backup=yes type=git-server
echo "                                                           "


        while true; do
            read -p "Enter the Git Repo name: " repo
            [[ -z $repo ]] && break
            cat ./overlays/development/add-repo.yaml >> ./overlays/development/add-repo-tempfile.yaml
	    cat ./overlays/development/add-volume-and-volumemount.yaml >> ./overlays/development/add-volume-and-volumemount-tempfile.yaml
	    sed -i "s,XX-namespace-XX,$namespace,g" ./base/git-server-tempfile.yaml
	    sed -i "s,XX-repo-XX,$repo,g" ./overlays/development/add-repo-tempfile.yaml
	    sed -i "s,XX-label-XX,$namespace,g" ./overlays/development/add-repo-tempfile.yaml
	    sed -i "s,XX-repo-XX,$repo,g" ./overlays/development/add-volume-and-volumemount-tempfile.yaml
	    sed -i "s,XX-label-XX,$namespace,g" ./overlays/development/add-volume-and-volumemount-tempfile.yaml
            sed -i "s,XX-namespace-XX,$namespace,g" ./overlays/development/add-repo-tempfile.yaml
            sed -i "s,XX-namespace-XX,$namespace,g" ./overlays/development/add-volume-and-volumemount-tempfile.yaml
	    
        done
./kustomize build ./overlays/development
kubectl apply -k ./overlays/development



echo -e "\nChecking pod status.....";  
  vChecksDone=1;
  vTotalChecks=10;
  while (( vChecksDone <= vTotalChecks ))
    do  
      vRetVal="$(kubectl get pod -n $namespace | awk 'FNR==2{print $3}')"
      if [[ "${vRetVal}" = "Running" ]]; then
         Vpodname="$(kubectl get pod -n $namespace | awk 'FNR==2{print $1}')"
         echo $Vpodname;
         kubectl cp ./scripts/mirror-git-repo.sh $namespace/$Vpodname:/tmp && 
         kubectl exec --stdin --tty $Vpodname -n $namespace -- /bin/bash -c "bash /tmp/mirror-git-repo.sh"
         break;
      fi   
      vChecksDone=$(( vChecksDone + 1 ));
      sleep 5
    done;
    if (( vChecksDone > vTotalChecks )); then
       printf "\n\n    pod is not ready and checking process has timed out.\n\n"          
       exit 1
    fi   