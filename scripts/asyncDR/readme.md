
# Remote Site Collaboration using AsyncDR Replication
## Prerequisites:

1. **kubectl (v1.23.4 or later) installed:** You can follow [official documentaion](https://kubernetes.io/docs/tasks/tools/) to install kubectl as per you operating environment.
Use following command to check version:
		
		kubectl version --client
2. **Portworx:** You will need 2 portworx clusters with AsyncDR license enabled. Portworx version 2.1 or later needs to be installed on both clusters. Also requires Stork v2.2+ on both of the clusters.
3. **KubeConfig files** You must have kube config files for both clusters.
4. **storkctl**: Run `storkctl version`. If it returns version number then it is installed, else install it with following commands. Make sure to replace the **<Provide-Full-Path-Of-Any-One-KubeConfig-File>** for **KUBECONFIG** variable:

	> Note: '**--retries**' parameter only works with kubectl v.1.23 or later (Tested with v.1.23.4). If this version is not available try without the option, but in some cases it fails with '**unexpected EOF**' error. In that situation please upgrade kubectl.

		export KUBECONFIG=<Provide-Full-Path-Of-Any-One-KubeConfig-File>
		STORK_POD=$(kubectl get pods --all-namespaces -l name=stork -o jsonpath='{.items[0].metadata.namespace} {.items[0].metadata.name}')
		kubectl cp -n "${STORK_POD% *}"  ${STORK_POD#* }:/storkctl/$(uname -s| awk '{print tolower($0)}')/storkctl ./storkctl --retries=20
		sudo mv storkctl /usr/local/bin
		sudo chmod +x /usr/local/bin/storkctl

5. **Secret Store :** Make sure you have configured a secret store on both your clusters. This will be used to store the credentials for the objectstore. Use following command to verify:

		kubectl get storageclusters --all-namespaces -o jsonpath='{.items[*].spec.secretsProvider}{"\n"}'

6. **Network Connectivity:** Ports 9001 and 9010 on the destination cluster should be reachable by the source cluster.
7. **Default Storage Class**: Make sure you have configured only one default storage class. Having multiple default storage classes will cause PVC migrations to fail. To verify you have only one default class configured run the following command. You should only see one default class in the list:
	
		kubectl get sc --kubeconfig=<Enter Path Of your Source Clusters Kubeconfig File>
	
		kubectl get sc --kubeconfig=<Enter Path Of your Destination Clusters Kubeconfig File>
	

Clone the current repository using  `git clone https://github.com/PureStorage-OpenConnect/px-gitops.git`.

## Steps:
### 1. Update the 'config-vars' file:
You will need to specify few values with correct information into the **config-vars** file.

	vi config-vars

These are the variables you will need to set in the file:

**PX_KUBECONF_FILE_SOURCE_CLUSTER:** Set path to the kube-config file for source cluster.

**PX_KUBECONF_FILE_DESTINATION_CLUSTER:** Set path to the kube-config file for destination cluster.

**PX_SCHEDULE_POLICY_INTERVAL_MINUTES:** Set interval time for schedule policy.
	
**PX_SCHEDULE_POLICY_DAILY_TIME:** Set time to schedule execution daily.

**PX_DST_NAMESPACE_SUFFIX:** Set suffix for the namespace on remote cluster. The "source namespace name+suffix" will be used as the name of namesapce on remote cluster.

Here is an example file arter setting up all the variables:

	# Line starting with # will be treated as a comment.

	##Set path to the kube-config files for source and destination clusters.
	  PX_KUBECONF_FILE_SOURCE_CLUSTER="/home/rbpcadmin/.kube/PS_Rancher"
	  PX_KUBECONF_FILE_DESTINATION_CLUSTER="/home/rbpcadmin/.kube/PS_BareMetal"

	##Set interval and daily execution time for schedule policy.
	  PX_SCHEDULE_POLICY_INTERVAL_MINUTES="10";  #720=12Hrs.
	  PX_SCHEDULE_POLICY_DAILY_TIME="1:33AM";

	##Set suffix for the namespace on remote cluster. The "source namespace name+suffix" will be used as the name of namesapce on remote cluster.
	  PX_DST_NAMESPACE_SUFFIX="remote";

### 2. Setup AsyncDR and replicate the git repository to the remote cluster.

This script will setup AsyncDR and replicate a repository to the remote cluster. After the repository is replicated, on remote cluster it will create a clone of the replicated repository into a new usable namespace.

>Note: We are creating the clone because we can not directly use the remote replica. Portworx needs all the PVCs free because it will be syncing data to it as per the schedule policy. So as a workarround we create clone and use that.

To find out what namespaces you have you can run the following command
	
	kubectl get ns --kubeconfig=<Enter Path Of your Source Clusters Kubeconfig File>
	
 For example if you want to replicate "springboot-code-main", run the script as follows.
 
	./start-async-repl.sh springboot-code-main
Once completed, you will see a namespace "springboot-code-main-remote". (Note the **'remote'** part in the name. It is same you set as suffix with **PX_DST_NAMESPACE_SUFFIX** variable)
To verify the remote replica run the following command:

	kubectl get all -n <EnterNameSpaceName> --kubeconfig=<Enter Path Of your Destination Clusters Kubeconfig File>


### 3. Re-Clone the remote replica to ger up-to-date data:

This step is not requred 1st time because it is automated in the previous script, but needs to be run whenever you want the latest data ready in the remote repository to get a pull or clone:

	./update.sh springboot-code-main
