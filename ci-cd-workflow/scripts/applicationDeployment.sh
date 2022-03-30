echo > ../argocd/manifests/application-deployment.yaml
echo > ../argocd/manifests/application-repo-secret.yaml
cp  ../argocd/manifests-template/application-deployment-template.yaml  ../argocd/manifests/application-deployment.yaml
cp ../argocd/manifests-template/application-repo-secret-template.yaml  ../argocd/manifests/application-repo-secret.yaml

CurrentClusterPath="$(echo $KUBECONFIG)"

echo "Enter the application  name"
read appName
sed -ie "s,XX-appName-XX,$appName,g" ../argocd/manifests/application-deployment.yaml
echo "                                         "
echo "Enter the application image name"
read imagename
sed -ie "s,XX-imagename-XX,$imagename,g" ../argocd/manifests/application-deployment.yaml

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

kubectl create secret generic regcred -n $namespace \
    --from-file=.dockerconfigjson=../config.json \
    --type=kubernetes.io/dockerconfigjson
    
echo "                                               " 
sed -ie "s,XX-namespace-XX,$namespace,g" ../argocd/manifests/application-deployment.yaml
source ../setup-vars/setup-vars
sed -ie "s,XX-url-XX,$gitRepoUrl,g" ../argocd/manifests/application-deployment.yaml
sed -ie "s,XX-path-XX,$directoryPath,g" ../argocd/manifests/application-deployment.yaml

encodedurl="$(echo -n $gitRepoUrl |  base64 )"
#echo $encodedurl
sed -ie "s,XX-app-code-url-XX,$encodedurl,g" ../argocd/manifests/application-repo-secret.yaml
#echo $ClusterKubeConfigFilePath
export KUBECONFIG=$ClusterKubeConfigFilePath

encodedId_rsaKey="$(kubectl get secret git-ssh-key -n $gitRepoNamespace  -o jsonpath='{.data.id_rsa}')"
sed -ie "s,XX-sshPrivatekey-XX,$encodedId_rsaKey,g" ../argocd/manifests/application-repo-secret.yaml
echo "                                            "
export KUBECONFIG=$CurrentClusterPath
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




