kubectl create ns argo-events &&
sleep 5
kubectl apply  -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml &&
sleep 5
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
