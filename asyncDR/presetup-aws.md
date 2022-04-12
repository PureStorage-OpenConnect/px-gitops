# Provide your AWS credentials to the source cluster

Commands in this doucment will add your AWS credentials for 

### Create a Secret with your AWS credentials on Source cluster .

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} -n portworx create secret generic --from-file=$HOME/.aws/credentials aws-creds

It will show you:

	secret/aws-creds created

### Pass this Secret to Stork (On source)

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

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} get pods -n portworx -l name=stork

When all the pods are up, Use following command to verify if stork is able to communicate with the destination cluster or not.
> Make sure to replace [stork-pod-name] with any of the stork pods returned by previous command.

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} -n portworx exec -ti [stork-pod-name] -- aws ec2 describe-availability-zones --region us-west-1

This command should list AZs in that aws region.
