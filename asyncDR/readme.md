
# Remote Site Collaboration using AsyncDR Replication

This document will help you to set up AsyncDR and replicate a git repository (namespace) to a remote cluster. In this setup, you will need two Portworx clusters accessible using kubectl. One will be your source cluster and another will be the destination (remote cluster). Once the repository is replicated to the destination cluster, a clone of the replica namespace will be created as a new namespace.

>Note: We are creating the clone because we can not directly use the remote replica. It remains in the standby state. Portworx needs all the PVCs free on the destination site because it will be syncing data as per the schedule policy. So as a workaround we create a secondary namespace using the PX-Clone to make the repository accessible.

## Prerequisites:

* **Softwares or Utilities required**: [**kubectl**](../install-utilities.md#kubectl-v1234-or-later), [**storkctl**](../install-utilities.md#storkctl)
* **KubeConfig files** You must have kube config files for both clusters.
* **Portworx (version 2.1 or later):** Both portworx clusters must have the AsyncDR license enabled and configured with Stork v2.2+.
* **A Git Repository Namespace on the Source:** You will need a Git Repository namespace on the source cluster, which you will migrate from the source cluster to the destination using AsyncDR.
* **Secret Store :** Configured secret store on both clusters. This will be used to store the credentials. Use the following command to verify:

		kubectl get storageclusters --all-namespaces -o jsonpath='{.items[*].spec.secretsProvider}{"\n"}' --kubeconfig=<Enter Path Of your Source Clusters Kubeconfig File>

		kubectl get storageclusters --all-namespaces -o jsonpath='{.items[*].spec.secretsProvider}{"\n"}' --kubeconfig==<Enter Path Of your Destination Clusters Kubeconfig File>

* **Network Connectivity:** Portworx API of the destination cluster should be reachable at the source cluster. If direct access is not possible, the AsyncDR setup script will create a k8s service.
* **Default Storage Class**: Make sure you have configured only one default storage class. Having multiple default storage classes will cause PVC migrations to fail. To verify you have only one default class configured run the following command. You should only see one default class in the list:

		kubectl get sc --kubeconfig=<Enter Path Of your Source Clusters Kubeconfig File>

		kubectl get sc --kubeconfig=<Enter Path Of your Destination Clusters Kubeconfig File>

## Prepare:

* ### Clone the current repository and switch to the AsyncDR folder:

		git clone https://github.com/PureStorage-OpenConnect/px-gitops.git
		cd px-gitops/asyncDR

* ### Set KUBE_CONF variables

	Set two separate variables with kube-config files, one for the source cluster and one for the destination. We will use these variables to perform checks and for getting information from the clusters.
	
	>Run these commands in the same terminal window. This will ensure both clusters are reachable and you can run the scripts from this window. 

		export KUBE_CONF_SOURCE=<Path to the Source cluster kubeconfig file>
		export KUBE_CONF_DESTINATON=<Path to the Destination cluster kubeconfig file>
	
	Verify if both variables are set up correctly by reaching out to the clusters:

		kubectl --kubeconfig=${KUBE_CONF_SOURCE} get nodes 
		kubectl --kubeconfig=${KUBE_CONF_DESTINATON} get nodes
	
* ### Setup cloud account credentials (Only required if the destination cluster is running on EKS or GKE)

	If your destination cluster is running on EKS or GKE you will need to pass your cloud provider account credentials to the Stork on the source cluster. Stork will use these credentials to get the k8s cluster access token.

	Please follow the respective link for your cloud provider:

	* [AWS-EKS](./presetup-aws.md)
	* [Google-GKE](./presetup-gke.md)

* ### Enable Authorization

	The source cluster will be reaching the Portworx API of the destination cluster through the internet, So it is recommended to enable the authorization on the destination in production environments. You may skip this if the setup is only for demo purposes.
	
	You can use following commands if you want to enable:

		kubectl --kubeconfig=${KUBE_CONF_DESTINATON} -n portworx patch storageclusters.core.libopenstorage.org px-cluster -p '{"spec":{"security":{"enabled":true}}}' --type=merge

	It will restart all the portworx and stork pods. Keep monitoring the pods until all the pods come up:

		kubectl --kubeconfig=${KUBE_CONF_DESTINATON} -n portworx get pods

	> Look at the **AGE** column to figure out if the pods have been restarted or not.

## Setup AsyncDR:

### 1. Set configuration variables

Create a configuration file from the template:

	cp templates/config-vars ./config-vars

You will need to specify a few values with correct information into the **config-vars** file.

	vi config-vars

Here is the information about the variables you will need to set in the file:

**PX_KUBECONF_FILE_SOURCE_CLUSTER** Set path to the kube-config file for source cluster.

**PX_KUBECONF_FILE_DESTINATION_CLUSTER** Set path to the kube-config file for destination cluster.

**PX_SCHEDULE_POLICY_INTERVAL_MINUTES** Set interval time for schedule policy in minutes. Set it to 60 or more. For demo purposes, you can set it to 10. 
	
**PX_SCHEDULE_POLICY_DAILY_TIME** Set time to schedule daily execution.

**PX_DST_NAMESPACE_SUFFIX** Set suffix for the namespace on the remote cluster. The "source namespace name+suffix" will be used as the name of the namespace on the remote cluster.

Here are some variables for S3 Bucket access, this bucket will be used as Object Store by portworx. It is not necessary to use only the AWS bucket, any s3 compatible bucket will work. For example, you can use "PureStorage FlashBlade s3 Bucket".

**PX_S3_ACCESS_KEY_ID** Set with your access key for the Bucket. 

**PX_S3_SECRET_KEY** Set with your secret access key for the Bucket.

**PX_S3_ENDPOINT** Set with the S3 bucket end-point. Use "s3.amazonaws.com" for AWS.

**PX_S3_DISABLE_SSL** Set it to "true" if the s3 endpoint does not support SSL, else set with "false".

**PX_AWS_REGION** Set with your s3 bucket region. It is ignored if the bucket is not an AWS bucket. Do not delete the variable if using a non-AWS bucket, leave it with the default value.

Here is the sample how all the variables look arter setting up all the values:

	PX_KUBECONF_FILE_SOURCE_CLUSTER="/home/user/.kube/vSphereVMs"
	PX_KUBECONF_FILE_DESTINATION_CLUSTER="/home/user/.kube/EKS"
	PX_SCHEDULE_POLICY_INTERVAL_MINUTES="10"
	PX_SCHEDULE_POLICY_DAILY_TIME="1:33AM"
	PX_DST_NAMESPACE_SUFFIX="remote"
	PX_S3_ACCESS_KEY_ID="CJG4MUD6ASJXZXQZCFJLQL"
	PX_S3_SECRET_KEY="0dBf/8j9D5k5GJxzXqz4vP/pc0NkcTZpbiiWEwse"
	PX_S3_ENDPOINT="s3.amazonaws.com"
	PX_S3_DISABLE_SSL="false"
	PX_AWS_REGION="us-west-2"

### 2. Setup AsyncDR and replicate the git repository to the remote cluster.
	
* List the available namespaces on the source and identify the one you want to replicate.
	
		kubectl get ns --kubeconfig=${KUBE_CONF_SOURCE}
	
* Now run the AsyncDR setup script specifying the desired namespace:
 	
		./start-async-repl.sh <NameSpace you want to replicate>

* The script will return two git URLs: Central and Remote. Set two variables with the URLs to avoid specifying the URLs with each command.

		GIT_REPO_URL_CENTRAL="Enter central repository URL"
		GIT_REPO_URL_REMOTE="Enter remote repository URL"

* Now check on the destination cluster, you will see two namespaces there: One with the same name as the source and another with a suffix "-remote". 

		kubectl get ns --kubeconfig=${KUBE_CONF_DESTINATON}

	> Note: The suffix **'remote'** is the same you set with the **PX_DST_NAMESPACE_SUFFIX** variable in the variables configuration file.

### 3. Verify and use the remote replica:
	
* To verify the remote replica run the following command:
	> Note: In the following command specify the namespace name with the suffix. 

		kubectl get all -n <EnterNameSpaceName> --kubeconfig=${KUBE_CONF_DESTINATON}

* Clone the remote repo.

	> * Find git user password [here](https://github.com/PureStorage-OpenConnect/px-gitops/tree/main/gitscm-server#credentails).
	> * Following commands will clone both repo's in different directories:
		
		git clone ${GIT_REPO_URL_CENTRAL} ~/central
		git clone ${GIT_REPO_URL_REMOTE} ~/remote

* Now preserve your current diretory and then switch to the remote repo cloned directory using following commands:

		ASYNC_DIR="$(pwd)"
		cd ~/remote
	
* Now add the central repository here, so you can push the changes to the central repo.

		git remote add central ${GIT_REPO_URL_CENTRAL}

	> The remote replica is read-only, so you can clone but can not push back to that.

* Make some changes and push to the central repo:

		echo "Some new code" > file
		git add file
		git commit -m "Adding new file."
		git push central
	
* Now to check if new changes are pushed to the central repository or not, first move to the central cloned directory and then do **git pull** as follows.

		cd ~/central
		git pull origin
		
### 4. Update the remote replica:

The changes in the central location are being synced to the standby namespace at the remote site as per the schedule policy. Since we can not directly use that namespace, we will need to update the secondary namespace whenever we need to get up-to-date data using git clone or git pull:

> * This step is not required 1st time because it is automated in the previous script, but needs to be run whenever you want the latest data ready in the remote repository to get a pull or clone.

1st change your current directory back to the asyncDR as follows:

	cd "${ASYNC_DIR}"

Now run the update.sh script to update the secondary namespace:

> * Enter namespace name without suffix.

	./update.sh <NameSpace name>

---
## Cleanup

You can use the following script to delete all the resources created by scripts in this document. The script will require the namespace name as a command-line parameter.

> The AsyncDR setup script will create Object-Store credentials and Portworx API service (If required). These resources are supposed to be created one time and will be re-used for other namespaces. If you also want to delete those, pass a 2nd parameter as '--all'

> Enter namespace name without the suffix.

Clean resources specific to the namespace only.

	./cleanup.sh <Namespace name>

Clean all resources created by the scripts.

	./cleanup.sh <Namespace name> --all

> The script will only remove the resources created by the AsyncDR setup script and update.sh scripts. If you have performed some manual tasks during the preparation process, this script will not undo those steps. For example, if you have enabled the authentication, the cleanup script will not disable that.

---
## Troubleshoot

All the scripts provided here perform tasks in the background and shows minimum required information on the screen to keep the display clean. If for some reason you want to check what is going on, you can look at the logs in **debug.log** file by running `tail -f debug.log` in a separate terminal window. 
