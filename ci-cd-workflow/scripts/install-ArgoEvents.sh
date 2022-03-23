kubectl create ns argo-events &&
sleep 1
kubectl apply  -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml &&
sleep 1
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
