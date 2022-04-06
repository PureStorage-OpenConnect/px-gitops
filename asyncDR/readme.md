
# Remote Site Collaboration using AsyncDR Replication
## Prerequisites:

1. **kubectl (v1.23.4 or later):** You can follow these steps to install kubectl as per you operating environment:

	Use following command to check:
		
		kubectl version --client

	If it is not installed use following commands to install:
	
	**Linux:**
	
		curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
		sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl
		
	**macOS:**
		
		brew install kubectl
		

2. **Portworx:** You will need 2 portworx clusters with AsyncDR license enabled. Portworx version 2.1 or later needs to be installed on both clusters. Also requires Stork v2.2+ on both of the clusters.
3. **KubeConfig files** You must have kube config files for both clusters.
4. **storkctl**: Run `storkctl version`. If it returns version number then it is installed, else install it with following commands. Make sure to replace the **< Provide-Full-Path-Of-Any-One-KubeConfig-File >** for **KUBECONFIG** variable:

	> Note: '**--retries**' parameter only works with kubectl v.1.23 or later (Tested with v.1.23.4). If this version is not available try without the **--retries** option, but in some cases it fails with '**unexpected EOF**' error. In that situation please upgrade kubectl.

		export KUBECONFIG=<Provide-Full-Path-Of-Any-One-KubeConfig-File>
		STORK_POD=$(kubectl get pods --all-namespaces -l name=stork -o jsonpath='{.items[0].metadata.namespace} {.items[0].metadata.name}')
		kubectl cp -n "${STORK_POD% *}"  ${STORK_POD#* }:/storkctl/$(uname -s| awk '{print tolower($0)}')/storkctl ./storkctl --retries=20
		sudo mv storkctl /usr/local/bin
		sudo chmod +x /usr/local/bin/storkctl

5. **Secret Store :** Make sure you have configured a secret store on both clusters. This will be used to store the credentials. Use following command to verify:

		kubectl get storageclusters --all-namespaces -o jsonpath='{.items[*].spec.secretsProvider}{"\n"}' --kubeconfig=<Enter Path Of your Source Clusters Kubeconfig File>

		kubectl get storageclusters --all-namespaces -o jsonpath='{.items[*].spec.secretsProvider}{"\n"}' --kubeconfig==<Enter Path Of your Destination Clusters Kubeconfig File>

6. **Network Connectivity:** Ports 9001 and 9010 of the destination cluster should be reachable on the source cluster.
7. **Default Storage Class**: Make sure you have configured only one default storage class. Having multiple default storage classes will cause PVC migrations to fail. To verify you have only one default class configured run the following command. You should only see one default class in the list:
	
		kubectl get sc --kubeconfig=<Enter Path Of your Source Clusters Kubeconfig File>

		kubectl get sc --kubeconfig=<Enter Path Of your Destination Clusters Kubeconfig File>

## Steps:

Clone the current repository and switch to the correct folder:
	
	git clone https://github.com/PureStorage-OpenConnect/px-gitops.git
	cd px-gitops/asyncDR

Now follow these steps:

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

This script will setup AsyncDR and replicate a repository namespace to the remote cluster. After the repository is replicated, on remote cluster it will create a clone of the replicated repository into a new usable namespace.

>Note: We are creating the clone because we can not directly use the remote replica. Portworx needs all the PVCs free on destination site because it will be syncing data as per the schedule policy. It remains in standby mode. So as a workarround we create a secondary namespace using the PX-Clone and start the application there.

1st set two separate variables with kube-config files, one for source cluster and one for the destination cluster. We will use this variables to perform checks and getting information from those clusters.

	export KUBE_CONF_SOURCE=<Path to the Source cluster kubeconfig file>
	export KUBE_CONF_DESTINATON=<Path to the Destination cluster kubeconfig file>
	
List the available namespaces on the source and identify the one you want to replicate.
	
	kubectl get ns --kubeconfig=${KUBE_CONF_SOURCE}
	
Now run the script specifying the desired namespace:
 	
	./start-async-repl.sh <NameSpace you want to replicate>
> Script will return two git URLs: Central and Remote. Please copy and save, you will need them in next steps.

Once completed, you will see two namespaces on the desitnation cluster. One with the same name as the source and another with a suffix "-remote". Use following command to check:
	
	kubectl get ns --kubeconfig=${KUBE_CONF_DESTINATON}

> Note: The suffix **'remote'** is the same you set with the **PX_DST_NAMESPACE_SUFFIX** variable in the variables configuration file.

### 3. Verify and use the remote replica:
	
To verify the remote replica run the following command:
> Note: In following command specify the namespace name with suffix. 

	kubectl get all -n <EnterNameSpaceName> --kubeconfig=${KUBE_CONF_DESTINATON}

* Now clone the remote repo.

	> Note: The previous AsyncDR setup script will provide the repo URL on completion. Find git user password [here](https://github.com/PureStorage-OpenConnect/px-gitops/tree/main/gitscm-server#credentails).

		git clone < Remote repository URL >

* Now from your terminal move to the cloned directory using following:

		cd < cloned directory name >
	
* Now add central repository here, so you can push the changes to the centeral repo.

		git remote add central < Central repository URL >

	> Note: The remote replica is read-only, so you can only clone but can not push back to that.

* Make some changes and push to the central repo: 

		echo "Some new code" > file
		git add file 
		git commit -m "Adding new file."
		git push central
	
### 4. Update the remote replica:

The changes in the central location are being synced to the standby namespace at remote site as per the schedule policy. Since we can not directly use that namespace, we will need to update the secondary namespace whenever we need to get up-to-date data using git clone or git pull:

> * This step is not requred 1st time because it is automated in the previous script, but needs to be run whenever you want the latest data ready in the remote repository to get a pull or clone.
> * Enter namespace name without sufix.

Note: Before running below command make sure your working directory is px-gitops/asyncDR

	./update.sh <NameSpace name>
---
### Cleanup

You can use the following script to delete all the resources created by scripts in this document. The script will require the namespace name as command-line parameter.

	./cleanup.sh <Namespace name>
