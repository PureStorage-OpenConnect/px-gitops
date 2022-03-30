kubectl create ns argo &&
Sleep 5
kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml &&
Sleep 5
kubectl patch svc argo-server -n argo -p '{"spec": {"type": "LoadBalancer"}}'
