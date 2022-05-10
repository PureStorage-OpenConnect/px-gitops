PS3=" Select the option for cleaning up the resources: "
select Cleanupoption in Clean-all-application Clean-applications-other-than-argo Clean-only-argo-applications ; do
  case $Cleanupoption in
  Clean-all-application)
  echo "                                 "
  echo "1) Deleting Argo-events resources"
  echo "                            "

  kubectl delete EventSource --all -n argo-events

  kubectl delete Sensor --all -n argo-events

  kubectl delete customresourcedefinition.apiextensions.k8s.io/eventbus.argoproj.io -n argo-events

  kubectl delete customresourcedefinition.apiextensions.k8s.io/eventsources.argoproj.io -n argo-events

  kubectl delete customresourcedefinition.apiextensions.k8s.io/sensors.argoproj.io -n argo-events

  kubectl delete serviceaccount/argo-events-sa -n argo-events

  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-events-aggregate-to-admin -n argo-events

  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-events-aggregate-to-edit  -n argo-events

  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-events-aggregate-to-view  -n argo-events

  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-events-role -n argo-events

  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argo-events-binding -n argo-events

# kubectl delete deployment.apps/eventbus-controller -n argo-events

# kubectl delete deployment.apps/eventsource-controller  -n argo-events

# kubectl delete deployment.apps/sensor-controller  -n argo-events
  kubectl delete deployment.apps/controller-manager  -n argo-events

  kubectl delete ns argo-events &&
  echo "                            "
  echo "2) Deleting Argo-workflow resources"
  echo "                            "
  kubectl delete customresourcedefinition.apiextensions.k8s.io/clusterworkflowtemplates.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/cronworkflows.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workfloweventbindings.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workflows.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workflowtaskresults.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workflowtasksets.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workflowtemplates.argoproj.io  -n argo
  kubectl delete serviceaccount/argo  -n argo
  kubectl delete serviceaccount/argo-server  -n argo
  kubectl delete serviceaccount/github.com  -n argo
  kubectl delete role.rbac.authorization.k8s.io/agent  -n argo
  kubectl delete role.rbac.authorization.k8s.io/argo-role  -n argo
  kubectl delete role.rbac.authorization.k8s.io/argo-server-role  -n argo
  kubectl delete role.rbac.authorization.k8s.io/executor  -n argo
  kubectl delete role.rbac.authorization.k8s.io/pod-manager  -n argo
  kubectl delete role.rbac.authorization.k8s.io/submit-workflow-template  -n argo
  kubectl delete role.rbac.authorization.k8s.io/workflow-manager  -n argo
  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-clusterworkflowtemplate-role  -n argo
  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-server-clusterworkflowtemplate-role  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/agent-default  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/argo-binding  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/argo-server-binding  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/executor-default  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/github.com  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/pod-manager-default  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/workflow-manager-default  -n argo
  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argo-clusterworkflowtemplate-role-binding  -n argo
  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argo-server-clusterworkflowtemplate-role-binding  -n argo
  kubectl delete configmap/artifact-repositories  -n argo
  kubectl delete configmap/workflow-controller-configmap  -n argo
  kubectl delete secret/argo-postgres-config  -n argo
  kubectl delete secret/argo-server-sso  -n argo
  kubectl delete secret/argo-workflows-webhook-clients  -n argo
  kubectl delete secret/my-minio-cred  -n argo
  kubectl delete service/argo-server  -n argo
  kubectl delete service/minio  -n argo
  kubectl delete service/postgres  -n argo
  kubectl delete service/workflow-controller-metrics  -n argo
  kubectl delete priorityclass.scheduling.k8s.io/workflow-controller  -n argo
  kubectl delete deployment.apps/argo-server  -n argo
  kubectl delete deployment.apps/minio  -n argo
  kubectl delete deployment.apps/postgres  -n argo
  kubectl delete deployment.apps/workflow-controller  -n argo
  kubectl delete secret --all -n argo
  kubectl delete ns argo &&
  echo "                            "
  echo "3) Deleting Argocd resources"
  echo "                            "
  kubectl delete customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io  -n argocd
  kubectl delete customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io  -n argocd
  kubectl delete customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io  -n argocd
  kubectl delete serviceaccount/argocd-application-controller  -n argocd
  kubectl delete serviceaccount/argocd-applicationset-controller  -n argocd
  kubectl delete serviceaccount/argocd-dex-server  -n argocd
  kubectl delete serviceaccount/argocd-notifications-controller  -n argocd
  kubectl delete serviceaccount/argocd-redis  -n argocd
  kubectl delete serviceaccount/argocd-server  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-application-controller  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-applicationset-controller  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-dex-server  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-notifications-controller  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-server  -n argocd
  kubectl delete clusterrole.rbac.authorization.k8s.io/argocd-application-controller  -n argocd
  kubectl delete clusterrole.rbac.authorization.k8s.io/argocd-server  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-application-controller  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-applicationset-controller  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-dex-server  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-notifications-controller  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-redis  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-server  -n argocd
  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argocd-application-controller  -n argocd
  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argocd-server  -n argocd
  kubectl delete configmap/argocd-cm  -n argocd
  kubectl delete configmap/argocd-cmd-params-cm  -n argocd
  kubectl delete configmap/argocd-gpg-keys-cm  -n argocd
  kubectl delete configmap/argocd-notifications-cm  -n argocd
  kubectl delete configmap/argocd-rbac-cm  -n argocd
  kubectl delete configmap/argocd-ssh-known-hosts-cm  -n argocd
  kubectl delete configmap/argocd-tls-certs-cm  -n argocd
  kubectl delete secret/argocd-notifications-secret  -n argocd
  kubectl delete secret/argocd-secret  -n argocd
  kubectl delete service/argocd-applicationset-controller  -n argocd
  kubectl delete service/argocd-dex-server  -n argocd
  kubectl delete service/argocd-metrics  -n argocd
  kubectl delete service/argocd-notifications-controller-metrics  -n argocd
  kubectl delete service/argocd-redis  -n argocd
  kubectl delete service/argocd-repo-server  -n argocd
  kubectl delete service/argocd-server  -n argocd
  kubectl delete service/argocd-server-metrics  -n argocd
  kubectl delete deployment.apps/argocd-applicationset-controller  -n argocd
  kubectl delete deployment.apps/argocd-dex-server  -n argocd
  kubectl delete deployment.apps/argocd-notifications-controller  -n argocd
  kubectl delete deployment.apps/argocd-redis  -n argocd
  kubectl delete deployment.apps/argocd-repo-server  -n argocd
  kubectl delete deployment.apps/argocd-server  -n argocd
  kubectl delete statefulset.apps/argocd-application-controller  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-application-controller-network-policy  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-dex-server-network-policy  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-redis-network-policy  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-repo-server-network-policy  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-server-network-policy  -n argocd
  kubectl delete serviceaccount/argocd-image-updater  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-image-updater  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-image-updater  -n argocd
  kubectl delete configmap/argocd-image-updater-config  -n argocd
  kubectl delete configmap/argocd-image-updater-ssh-config  -n argocd
  kubectl delete secret/argocd-image-updater-secret  -n argocd
  kubectl delete deployment.apps/argocd-image-updater  -n argocd
  kubectl delete ns argocd &&
  echo "                            "
  echo "4) Deleting applications deployed using argocd"
  echo "                             "
  kubectl delete ns --selector=controller=ci-cd && 

  echo "                            "
  echo "5) Deleting git repository"
  echo "                             "
  kubectl delete ns --selector=type=git-server &&

  echo "                            "
  echo "6) Deleting Storage class"
  echo "                             "
  kubectl delete sc px-db-sc px-file-sc px-gitrepo-sc
  break
  ;;

  Clean-applications-other-than-argo)
  echo "                             "
  echo "1) Deleting argo EventSource and Sensor"
  echo "                             "
  kubectl delete svc -n argo-events --selector=controller=ci-cd &&
  kubectl delete EventSource --all -n argo-events && 
  kubectl delete Sensor --all -n argo-events
  
  echo "                             "
  echo "2) Deleting applications deployed using argocd"
  echo "                             "
  kubectl delete application --all -n argocd
  kubectl delete ns --selector=controller=ci-cd && 

  echo "                            "
  echo "3) Deleting git repository"
  echo "                             "
  kubectl delete ns --selector=type=git-server &&

  echo "                            "
  echo "4) Deleting Storage class"
  echo "                             "
  kubectl delete sc px-db-sc px-file-sc px-gitrepo-sc
  
  echo "5) Deleting application secret  from argo namespace"
  echo "                             "
  kubectl delete secret --selector=app=argo-wokflow-secret -n argo
  break
  ;;
  
  Clean-only-argo-applications)
  echo "                                 "
  echo "1) Deleting Argo-events resources"
  Output="No resources found in argo-events namespace."
  EventSource="$(kubectl get EventSource -n argo-events 2>&1 )"
  Sensor="$(kubectl get Sensor -n argo-events 2>&1 )"
  if [[ "$EventSource" == "$Output" && "$Sensor" == "$Output" ]]; then
  echo "                           "
  else
    kubectl delete EventSource --all -n argo-events
    kubectl delete Sensor --all -n argo-events
  fi
  kubectl delete customresourcedefinition.apiextensions.k8s.io/eventbus.argoproj.io -n argo-events

  kubectl delete customresourcedefinition.apiextensions.k8s.io/eventsources.argoproj.io -n argo-events

  kubectl delete customresourcedefinition.apiextensions.k8s.io/sensors.argoproj.io -n argo-events

  kubectl delete serviceaccount/argo-events-sa -n argo-events

  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-events-aggregate-to-admin -n argo-events

  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-events-aggregate-to-edit  -n argo-events

  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-events-aggregate-to-view  -n argo-events

  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-events-role -n argo-events

  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argo-events-binding -n argo-events

# kubectl delete deployment.apps/eventbus-controller -n argo-events

# kubectl delete deployment.apps/eventsource-controller  -n argo-events

# kubectl delete deployment.apps/sensor-controller  -n argo-events
  kubectl delete deployment.apps/controller-manager  -n argo-events

  kubectl delete ns argo-events &&
  echo "                            "
  echo "2) Deleting Argo-workflow resources"
  echo "                            "
  kubectl delete customresourcedefinition.apiextensions.k8s.io/clusterworkflowtemplates.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/cronworkflows.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workfloweventbindings.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workflows.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workflowtaskresults.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workflowtasksets.argoproj.io  -n argo
  kubectl delete customresourcedefinition.apiextensions.k8s.io/workflowtemplates.argoproj.io  -n argo
  kubectl delete serviceaccount/argo  -n argo
  kubectl delete serviceaccount/argo-server  -n argo
  kubectl delete serviceaccount/github.com  -n argo
  kubectl delete role.rbac.authorization.k8s.io/agent  -n argo
  kubectl delete role.rbac.authorization.k8s.io/argo-role  -n argo
  kubectl delete role.rbac.authorization.k8s.io/argo-server-role  -n argo
  kubectl delete role.rbac.authorization.k8s.io/executor  -n argo
  kubectl delete role.rbac.authorization.k8s.io/pod-manager  -n argo
  kubectl delete role.rbac.authorization.k8s.io/submit-workflow-template  -n argo
  kubectl delete role.rbac.authorization.k8s.io/workflow-manager  -n argo
  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-clusterworkflowtemplate-role  -n argo
  kubectl delete clusterrole.rbac.authorization.k8s.io/argo-server-clusterworkflowtemplate-role  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/agent-default  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/argo-binding  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/argo-server-binding  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/executor-default  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/github.com  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/pod-manager-default  -n argo
  kubectl delete rolebinding.rbac.authorization.k8s.io/workflow-manager-default  -n argo
  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argo-clusterworkflowtemplate-role-binding  -n argo
  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argo-server-clusterworkflowtemplate-role-binding  -n argo
  kubectl delete configmap/artifact-repositories  -n argo
  kubectl delete configmap/workflow-controller-configmap  -n argo
  kubectl delete secret/argo-postgres-config  -n argo
  kubectl delete secret/argo-server-sso  -n argo
  kubectl delete secret/argo-workflows-webhook-clients  -n argo
  kubectl delete secret/my-minio-cred  -n argo
  kubectl delete service/argo-server  -n argo
  kubectl delete service/minio  -n argo
  kubectl delete service/postgres  -n argo
  kubectl delete service/workflow-controller-metrics  -n argo
  kubectl delete priorityclass.scheduling.k8s.io/workflow-controller  -n argo
  kubectl delete deployment.apps/argo-server  -n argo
  kubectl delete deployment.apps/minio  -n argo
  kubectl delete deployment.apps/postgres  -n argo
  kubectl delete deployment.apps/workflow-controller  -n argo
  kubectl delete secret --all -n argo
  kubectl delete ns argo &&
  echo "                            "
  echo "3) Deleting Argocd resources"
  echo "                            "
  kubectl delete customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io  -n argocd
  kubectl delete customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io  -n argocd
  kubectl delete customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io  -n argocd
  kubectl delete serviceaccount/argocd-application-controller  -n argocd
  kubectl delete serviceaccount/argocd-applicationset-controller  -n argocd
  kubectl delete serviceaccount/argocd-dex-server  -n argocd
  kubectl delete serviceaccount/argocd-notifications-controller  -n argocd
  kubectl delete serviceaccount/argocd-redis  -n argocd
  kubectl delete serviceaccount/argocd-server  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-application-controller  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-applicationset-controller  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-dex-server  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-notifications-controller  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-server  -n argocd
  kubectl delete clusterrole.rbac.authorization.k8s.io/argocd-application-controller  -n argocd
  kubectl delete clusterrole.rbac.authorization.k8s.io/argocd-server  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-application-controller  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-applicationset-controller  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-dex-server  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-notifications-controller  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-redis  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-server  -n argocd
  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argocd-application-controller  -n argocd
  kubectl delete clusterrolebinding.rbac.authorization.k8s.io/argocd-server  -n argocd
  kubectl delete configmap/argocd-cm  -n argocd
  kubectl delete configmap/argocd-cmd-params-cm  -n argocd
  kubectl delete configmap/argocd-gpg-keys-cm  -n argocd
  kubectl delete configmap/argocd-notifications-cm  -n argocd
  kubectl delete configmap/argocd-rbac-cm  -n argocd
  kubectl delete configmap/argocd-ssh-known-hosts-cm  -n argocd
  kubectl delete configmap/argocd-tls-certs-cm  -n argocd
  kubectl delete secret/argocd-notifications-secret  -n argocd
  kubectl delete secret/argocd-secret  -n argocd
  kubectl delete service/argocd-applicationset-controller  -n argocd
  kubectl delete service/argocd-dex-server  -n argocd
  kubectl delete service/argocd-metrics  -n argocd
  kubectl delete service/argocd-notifications-controller-metrics  -n argocd
  kubectl delete service/argocd-redis  -n argocd
  kubectl delete service/argocd-repo-server  -n argocd
  kubectl delete service/argocd-server  -n argocd
  kubectl delete service/argocd-server-metrics  -n argocd
  kubectl delete deployment.apps/argocd-applicationset-controller  -n argocd
  kubectl delete deployment.apps/argocd-dex-server  -n argocd
  kubectl delete deployment.apps/argocd-notifications-controller  -n argocd
  kubectl delete deployment.apps/argocd-redis  -n argocd
  kubectl delete deployment.apps/argocd-repo-server  -n argocd
  kubectl delete deployment.apps/argocd-server  -n argocd
  kubectl delete statefulset.apps/argocd-application-controller  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-application-controller-network-policy  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-dex-server-network-policy  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-redis-network-policy  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-repo-server-network-policy  -n argocd
  kubectl delete networkpolicy.networking.k8s.io/argocd-server-network-policy  -n argocd
  kubectl delete serviceaccount/argocd-image-updater  -n argocd
  kubectl delete role.rbac.authorization.k8s.io/argocd-image-updater  -n argocd
  kubectl delete rolebinding.rbac.authorization.k8s.io/argocd-image-updater  -n argocd
  kubectl delete configmap/argocd-image-updater-config  -n argocd
  kubectl delete configmap/argocd-image-updater-ssh-config  -n argocd
  kubectl delete secret/argocd-image-updater-secret  -n argocd
  kubectl delete deployment.apps/argocd-image-updater  -n argocd
  kubectl delete ns argocd &&   
  break
  ;;
  esac
done 
