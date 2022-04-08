kubectl create namespace argocd &&
sleep 5
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml &&
sleep 5
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/applicationset/master/manifests/install.yaml
sleep 4
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
sleep 5
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
sleep 4
kubectl create ns argo &&
Sleep 5
kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml &&
Sleep 5
kubectl patch svc argo-server -n argo -p '{"spec": {"type": "LoadBalancer"}}'
sleep 4
kubectl create ns argo-events &&
sleep 5
kubectl apply  -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml &&
sleep 5
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
if (kubectl get sc | grep px-file-sc  && kubectl get sc | grep px-db-sc ) 2>&1 >/dev/null
    then 
    echo "                 "
    else
    echo "                 "
    echo "No storage class was found. Created new storage class for application."
    kubectl apply -f ../storage-class-manifests/storage-classes.yml
fi
