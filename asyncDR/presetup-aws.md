# Provide your AWS credentials to the source cluster

Commands in this doucment will pass your AWS credentials to Stork. Stork need these details to authenticate to the destination k8s cluster.

Find Portworx storage cluster name and Portworx installation namespace you will need them in next commands:

> Hope you have the **KUBE_CONF_SOURCE** variable set as mentioned in the main [readme](./readme.md#set-kube_conf-variables) file.

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} get storagecluster --all-namespaces

This will show you cluster information, please note down the namespace and name of the cluster.

### Create a Secret with your AWS credentials on Source cluster.
	
> Update the portworx namespace in '-n portworx' parameter if it is different. 

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} -n portworx create secret generic --from-file=$HOME/.aws/credentials aws-creds

It will show you:

	secret/aws-creds created

### Pass this Secret to Stork (On source)

> Update the 'px-cluster' and '-n portworx' parameteres if required.

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} edit storagecluster px-cluster -n portworx

This will open the storagecluster spec in the editor, you need to add following at **spec.stork**:
```
    volumes:
    - mountPath: /root/.aws
      name: aws-creds
      readOnly: true
      secret:
        secretName: aws-creds
```
After editing the stork section of  the storagecluster spec should look like:
```
...
...
    stork:
      args:
        webhook-controller: "false"
      enabled: true
      volumes:
      - mountPath: /root/.aws
        name: aws-creds
        readOnly: true
        secret:
          secretName: aws-creds
...
...
```

Save the changes and wait for all the Stork pods to be in running state after applying the changes:

> Update the portworx namespace in '-n portworx' parameter if it is different. 

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} get pods -n portworx -l name=stork

When all the pods are up, Use following command to verify if stork is able to communicate with the destination cluster or not.

> * Update the portworx namespace in '-n portworx' parameter if it is different. 
> * Make sure to replace [stork-pod-name] with any of the stork pods returned by previous command.

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} -n portworx exec -ti [stork-pod-name] -- aws ec2 describe-availability-zones --region us-west-1

This command should list AZs in that aws region.
