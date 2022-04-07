
# Autopilot for git-server
This script will set an Autopilot rule to auto expand the PVCs when the usage reaches the specified limit in percentage.

## Pre-requisites:
- Access to a running portworx cluster with Autopilot.
- A running git-server on that cluster. Check [gitscm-server](https://github.com/PureStorage-OpenConnect/px-gitops/tree/main/gitscm-server) to create a new one.
- Installed: kubectl and git (to clone this repo).

## Here are the steps:

**To start the deployment for the first time**

Clone the current repository using

    git clone https://github.com/PureStorage-OpenConnect/px-gitops.git

Then in your terminal change the directory

    cd px-gitops/autopilot
    
    
### 1. Set the configuration variables:

Edit the **config-vars** file to set the variables. Here is the description about each variable:

**VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION:** Set the limit in percentage, so Autopilot can take the specified action once this limit is reached. 

**SCALE_PERCENTAGE:** Provide the amount of space in percentage to expand when the usage limit is reached.

**VOLUME_MAX_SIZE:** Provide the maximum size limit so the Autopilot can stop further expansion of the volumes. If this limit is reached Autopilot will take no more actions to expand the volumes.

Here is the sample file with all the variables set:

	  VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION="50"
	  SCALE_PERCENTAGE="50"
	  VOLUME_MAX_SIZE="30Gi"



### 2. To create a rule for Autopilot.

Call the script as follows. The script will provide the **rule name** which we will use in next command to verify the rule.

	./setup-autopilot-rule.sh

> Note the rule name in the output of command. We will use this name in the next command to verify it.
	
Use following command to verify the rule:	
	
	kubectl describe autopilotrule <rule-name>

> Note: Autopilot rules are applied globally on all git-server namespaces.

### 3. Testing: Fillup PVCs with some data files:

- Identify the git-server namespace you want to run the test on:
	
		kubectl get ns
	
- Set a variable with namespace name:

		export NS_NAME=<Replace with the name namespace>

- Check current PVC stats in the namespace:
	
		kubectl get pvc -n ${NS_NAME}
	
- Call the script to fill up the PVC.

	The script takes two parameters:
	1. Namespace name
	2. Total size of the data files (in GB) you want to write on the PVC.
	
	So here we are writing 6GB of data files to the PVC:

		./workload.sh ${NS_NAME} 6

	Once done the script will show the latest volume stats.

	> This script will create data files in the pod at /home/git/repos/[repo-name]/data-file-[time-stamp] for demo purposes. You can delete them by logging into your git server pod manually to help speed up the demo process.


- Now check the new size of the PVC:

	It can take approx 5 minutes for autopilot to take the action on the PVC. So you can keep trying the following command until the size is expanded:

		kubectl get pvc -n ${NS_NAME}
	
