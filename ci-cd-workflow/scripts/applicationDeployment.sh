#Creating empty files
echo > ../argocd/manifests/application-deployment.yaml
echo > ../argocd/manifests/application-repo-secret.yaml

#Copying temlplate to main manifests file
cp  ../argocd/manifests-template/application-deployment-template.yaml  ../argocd/manifests/application-deployment.yaml
cp ../argocd/manifests-template/application-repo-secret-template.yaml  ../argocd/manifests/application-repo-secret.yaml

vCONFIGFILE=../setup-vars/setup-vars

PS3=" Select the application you want to deploy: "
select gitoption in java-app wordpress-app; do
  case $gitoption in 
  java-app)
  sed -ie "s,XX-appName-XX,springboot-app,g" ../argocd/manifests/application-deployment.yaml
  source ${vCONFIGFILE}
  sed -ie "s,XX-imagename-XX,$Java_Docker_Image_Main_Branch,g" ../argocd/manifests/application-deployment.yaml 
  break
  ;;
  wordpress-app)
  sed -ie "s,XX-appName-XX,wordpress-app,g" ../argocd/manifests/application-deployment.yaml
  source ${vCONFIGFILE}
  sed -ie "s,XX-imagename-XX,$Wordpress_Docker_Image_Main_Branch,g" ../argocd/manifests/application-deployment.yaml
  break
  ;;
  esac
done  
number="$(echo $RANDOM)"
sed -ie "s,XX-number-XX,$number,g" ../argocd/manifests/application-repo-secret.yaml
sed -ie "s,XX-number-XX,$number,g" ../argocd/manifests/application-deployment.yaml
echo "                                         "
argocdServiceIP="$(kubectl get svc argocd-server -n argocd | awk 'FNR==2{print $4}')"

#echo "Enter argocd UI domain name or IP without http"
#read ipDomain
echo "                                         "
echo "Enter application destination information, in which you want to deploy"
echo "namespace-name"
read namespace
echo "                                         "

kubectl create ns $namespace
kubectl label ns $namespace controller=ci-cd
kubectl create secret generic regcred -n $namespace \
    --from-file=.dockerconfigjson=../config.json \
    --type=kubernetes.io/dockerconfigjson
echo "                                               " 
sed -ie "s,XX-namespace-XX,$namespace,g" ../argocd/manifests/application-deployment.yaml

##Setting kube-configs.
source ${vCONFIGFILE}
PodName="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH get all -n $PX_Application_MainBranch_Namespace | awk 'FNR == 2 {print$1}' | cut -d"/" -f2)"
EXTERNALIP="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH get all -n $PX_Application_MainBranch_Namespace | grep  -A1 "EXTERNAL-IP" | awk 'FNR == 2 {print$4}')"
REPONAME="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH describe pods $PodName -n $PX_Application_MainBranch_Namespace | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}')"
gitRepoUrl="ssh://git@$EXTERNALIP/home/git/repos/$REPONAME"
sed -ie "s,XX-url-XX,$gitRepoUrl,g" ../argocd/manifests/application-deployment.yaml
sed -ie "s,XX-path-XX,manifest/overlays/development,g" ../argocd/manifests/application-deployment.yaml

encodedurl="$(echo -n $gitRepoUrl |  base64 )"
sed -ie "s,XX-app-code-url-XX,$encodedurl,g" ../argocd/manifests/application-repo-secret.yaml

encodedId_rsaKey="$(kubectl --kubeconfig=$PX_Application_MainBranch_KUBECONF_PATH get secret git-ssh-key -n $PX_Application_MainBranch_Namespace  -o jsonpath='{.data.id_rsa}')"
sed -ie "s,XX-sshPrivatekey-XX,$encodedId_rsaKey,g" ../argocd/manifests/application-repo-secret.yaml
echo "                                            "
echo "adding jfrog docker registry details to argocd"
kubectl apply -f ../argocd/manifests/jfrog-credentials.yaml
kubectl apply -f ../argocd/manifests/jfrog-registry-configmap.yaml
echo "                                            "
echo "restarting argocd-image-updater deployment"
echo "                                            "
kubectl rollout restart deployment argocd-image-updater -n argocd
sleep 5
echo "argocd-image-updater deployment restarted successfully"
echo "                                            "
kubectl apply -f ../argocd/manifests/application-repo-secret.yaml
sleep 2
kubectl apply -f  ../argocd/manifests/application-deployment.yaml

countsetupVars=`ls -1 ../argocd/manifests/*.yamle 2>/dev/null | wc -l`
if [ $countsetupVars != 0 ]
then 
rm ../argocd/manifests/*.yamle
fi




