#!/bin/bash
set -e -u
set -o pipefail

echo > ./overlays/development/add-repo.yaml
echo > ./overlays/development/add-volume-and-volumemount.yaml
echo > ./base/git-server.yaml
cp ./template/git-server.yaml ./base/git-server.yaml

PS3=" Select the option for which you want to deploy Git server: "
select gitoption in Git-server-for-Dockerfiles Git-server-for-application; do
  case $gitoption in 
  Git-server-for-Dockerfiles)
        if kubectl get sc | grep px-gitrepo-sc 2>&1 >/dev/null
    then 
    echo "                 "
    else
    kubectl apply -f px-gitrepo-sc.yaml
    fi

    echo "                                                           "
    echo "Enter namespace in which you want to deploy"
    read namespace
    sed -ie "s,XX-label-XX,$namespace,g" ./base/git-server.yaml
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
    mkdir -p gitserver-sshkey
    mkdir -p ./gitserver-sshkey/$namespace && mv id_rsa id_rsa.pub ./gitserver-sshkey/$namespace
    echo "                                                           "
    echo "Enter the dockerfile path of your local system"
    read dockerPath
    #echo "Enter the repo name with suffix '.git' from above git repo url you just entered"
    #read repo
    kubectl create secret generic deployment --from-file=./scripts/deploy.sh  -n $namespace
    kubectl label secret deployment -n $namespace  app=git-server-for-$namespace include-in-backup=yes type=git-server
    echo "                                                           "
    echo "You must enter a minimum of one Repo name. If you do not want to enter more than one repo or have entered all desired repo names leave repo name blank and press 'enter' to execute"

            while true; do
                read -p "Enter the Git Repo name: " repo
                [[ -z $repo ]] && break
                cat ./template/add-repo.yaml >> ./overlays/development/add-repo.yaml
          cat ./template/add-volume-and-volumemount.yaml >> ./overlays/development/add-volume-and-volumemount.yaml
          sed -ie "s,XX-namespace-XX,$namespace,g" ./base/git-server.yaml
          sed -ie "s,XX-repo-XX,$repo,g" ./overlays/development/add-repo.yaml
          sed -ie "s,XX-label-XX,$namespace,g" ./overlays/development/add-repo.yaml
          sed -ie "s,XX-repo-XX,$repo,g" ./overlays/development/add-volume-and-volumemount.yaml
          sed -ie "s,XX-label-XX,$namespace,g" ./overlays/development/add-volume-and-volumemount.yaml
                sed -ie "s,XX-namespace-XX,$namespace,g" ./overlays/development/add-repo.yaml
                sed -ie "s,XX-namespace-XX,$namespace,g" ./overlays/development/add-volume-and-volumemount.yaml
          
            done

    kubectl apply -k ./overlays/development
    sleep 2

    countBase=`ls -1 ./base/*.yamle 2>/dev/null | wc -l`
    countOverlays=`ls -1 ./overlays/development/*.yamle 2>/dev/null | wc -l`
    if [ "$countBase" != "0" ] && [ "$countOverlays" != "0" ]
    then 
    rm ./base/*.yamle
    rm ./overlays/development/*.yamle
    fi
    sleep 1


    echo -e "\nChecking pod status.....";  
      vChecksDone=1;
      vTotalChecks=10;
      while (( vChecksDone <= vTotalChecks ))
        do  
          vRetVal="$(kubectl get pod -n $namespace | awk 'FNR==2{print $3}')"
          if [[ "${vRetVal}" = "Running" ]]; then
            Vpodname="$(kubectl get pod -n $namespace | awk 'FNR==2{print $1}')"
            echo $Vpodname;
            kubectl exec --stdin --tty $Vpodname -n $namespace -- /bin/bash -c "mkdir /home/git/dockerfile" &&
            kubectl cp $dockerPath/ $namespace/$Vpodname:/home/git/dockerfile
            kubectl cp ./scripts/git-setup-for-dockerfile.sh $namespace/$Vpodname:/tmp
            kubectl exec --stdin --tty $Vpodname -n $namespace -- /bin/bash -c "bash /tmp/git-setup-for-dockerfile.sh"

            break;
          fi   
          vChecksDone=$(( vChecksDone + 1 ));
          sleep 5
        done;
        if (( vChecksDone > vTotalChecks )); then
          printf "\n\n    pod is not ready and checking process has timed out.\n\n"          
          exit 1
        fi   
  break
  ;;
  Git-server-for-application)
    if kubectl get sc | grep px-gitrepo-sc 2>&1 >/dev/null
    then 
    echo "                 "
    else
    kubectl apply -f px-gitrepo-sc.yaml
    fi

    echo "                                                           "
    echo "Enter namespace in which you want to deploy"
    read namespace
    sed -ie "s,XX-label-XX,$namespace,g" ./base/git-server.yaml
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
    mkdir -p gitserver-sshkey
    mkdir -p ./gitserver-sshkey/$namespace && mv id_rsa id_rsa.pub ./gitserver-sshkey/$namespace
    echo "                                                           "
    cp ./scripts/mirror-git-repo-template.sh ./scripts/mirror-git-repo.sh
    echo "Enter the existing git repo url to want to mirror "
    read url
    #echo "                                                           "
    #echo "Enter the repo name with suffix '.git' from above git repo url you just entered"
    #read repo
    repo="$(echo $url | cut -d"/" -f5)"
    sed -ie "s,XX-url-XX,$url,g" ./scripts/mirror-git-repo.sh
    sed -ie "s,XX-repo-XX,$repo,g" ./scripts/mirror-git-repo.sh
    kubectl create secret generic deployment --from-file=./scripts/deploy.sh  -n $namespace
    kubectl label secret deployment -n $namespace  app=git-server-for-$namespace include-in-backup=yes type=git-server
    echo "                                                           "
    echo "You must enter a minimum of one Repo name. If you do not want to enter more than one repo or have entered all desired repo names leave repo name blank and press 'enter' to execute"

            while true; do
                read -p "Enter the Git Repo name: " repo
                [[ -z $repo ]] && break
                cat ./template/add-repo.yaml >> ./overlays/development/add-repo.yaml
          cat ./template/add-volume-and-volumemount.yaml >> ./overlays/development/add-volume-and-volumemount.yaml
          sed -ie "s,XX-namespace-XX,$namespace,g" ./base/git-server.yaml
          sed -ie "s,XX-repo-XX,$repo,g" ./overlays/development/add-repo.yaml
          sed -ie "s,XX-label-XX,$namespace,g" ./overlays/development/add-repo.yaml
          sed -ie "s,XX-repo-XX,$repo,g" ./overlays/development/add-volume-and-volumemount.yaml
          sed -ie "s,XX-label-XX,$namespace,g" ./overlays/development/add-volume-and-volumemount.yaml
                sed -ie "s,XX-namespace-XX,$namespace,g" ./overlays/development/add-repo.yaml
                sed -ie "s,XX-namespace-XX,$namespace,g" ./overlays/development/add-volume-and-volumemount.yaml
          
            done

    kubectl apply -k ./overlays/development
    sleep 2

    countBase=`ls -1 ./base/*.yamle 2>/dev/null | wc -l`
    countOverlays=`ls -1 ./overlays/development/*.yamle 2>/dev/null | wc -l`
    countScripts=`ls -1 ./scripts/*.she 2>/dev/null | wc -l`
    if [ "$countBase" != "0" ] && [ "$countOverlays" != "0" ] && [ "$countScripts" != "0" ]
    then 
    rm ./base/*.yamle
    rm ./overlays/development/*.yamle
    rm ./scripts/*.she
    fi
    sleep 1


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
  break
  ;;
  esac
done  
