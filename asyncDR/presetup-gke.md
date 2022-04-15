# Provide your Google Cloud (GCP) credentials to the source cluster

Commands in this doucment will pass Google Cloud credentials of your destination cluster to Stork running at the source cluster. Stork will need these details to authenticate to the destination k8s cluster.

Find Portworx storage cluster name and Portworx installation namespace on the source. You will need them in next commands:

> Make sure you have the **KUBE_CONF_SOURCE** variable set as mentioned in the main [readme](./readme.md#set-kube_conf-variables) file.

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} get storagecluster --all-namespaces

This will show you cluster information, please note down the namespace and name of the cluster.

### Create a json key of your Google Cloud service account:

You can create this using the following command:

> If you already have a servic account key, you can skip this command and use your existing key in next steps.

  gcloud iam service-accounts keys create gcs-key.json --iam-account <your_iam_account>

> Guide from Google Cloud to [generate a service-account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys).


### Create a Secret from the service-account key.
	
> Update the portworx namespace in '-n portworx' parameter if it is different.

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} -n portworx create secret generic --from-file=./gcs-key.json gke-creds

It will show you:

	secret/gke-creds created

### Pass this Secret to Stork (On source)

> Update the 'px-cluster' and '-n portworx' parameteres if required.

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} edit storagecluster px-cluster -n portworx

This will open the storagecluster spec in the editor, you need to add following at **spec.stork**:

```
    env:
    - name: CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE
      value: /root/.gke/gcs-key.json
    volumes:
    - mountPath: /root/.gke
      name: gke-creds
      readOnly: true
      secret:
        secretName: gke-creds
```
After editing, the stork section of the storagecluster spec should look like:

```
...
...
  stork:
    args:
      webhook-controller: "false"
    enabled: true
    env:
    - name: CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE
      value: /root/.gke/gcs-key.json
    volumes:
    - mountPath: /root/.gke
      name: gke-creds
      readOnly: true
      secret:
        secretName: gke-creds
...
...
```

Save the changes and wait for all the Stork pods to be in running state after applying the changes:

> Update the portworx namespace in '-n portworx' parameter if it is different. 

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} get pods -n portworx -l name=stork

When all the pods are up use following command to verify if stork is able to communicate with the destination cluster or not.

> * Update the portworx namespace in '-n portworx' parameter if it is different. 
> * Make sure to replace [stork-pod-name] with any of the stork pods returned by previous command.

	kubectl --kubeconfig=${KUBE_CONF_SOURCE} -n portworx exec -ti [stork-pod-name] -- /google-cloud-sdk/bin/gcloud projects list

This command will show the project name, which means the credentials are working fine.
