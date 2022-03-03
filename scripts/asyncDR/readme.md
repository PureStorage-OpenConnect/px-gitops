# Remote Site Replication using AsyncDR
## Prerequistes:

1. You will need 2 portworx clusters with AsyncDR license enabled.
2. storkctl installd. run `storkctl version` if it returns version number the it is installed, else follow the documentation to install it:  

**Version:** Portworx v2.1 or later needs to be installed on both clusters. Also requires Stork v2.2+ on both the clusters.
**Secret Store :** Make sure you have configured a secret store on both your clusters. This will be used to store the credentials for the objectstore.
**Network Connectivity:** Ports 9001 and 9010 on the destination cluster should be reachable by the source cluster.
Stork helper: storkctl is a command-line tool for interacting with a set of scheduler extensions.
**Default Storage Class**: Make sure you have configured only one default storage class. Having multiple default storage classes will cause PVC migrations to fail.
**Utilities:** storkctl, kubectl, awk and sed

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

This script will setup AsyncDR and replicate a repository to the remote cluster. Once the repository is replicated to the remote cluster, then it will create a clone of the remote repository into a new namespace.

>Note: Creating the clone is required. We can not directly use the remote replica because portworx will be syncing data to it as per the schedule policy.

 For example if you want to replicate "springboot-code-main", run the script as follows.

	./start-async-repl.sh springboot-code-main
Once completed, you will see a namespace "springboot-code-main-remote". (Note the **'remote'** part in the name. It is same you set as suffix with **PX_DST_NAMESPACE_SUFFIX** variable)
To verify the remote replica run the following command:

	kubectl get all -n springboot-code-main-remote --kubeconfig=replace-with-the-kube-config-file-path-for-remote-cluster


### 3. Re-Clone the remote replica to ger up-to-date data:

This step is not requred 1st time because it is automated in the previous script, but needs to be run whenever you want the latest data ready in the remote repository:

	./update.sh springboot-code-main