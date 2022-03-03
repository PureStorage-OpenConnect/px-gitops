
# Autopilot configuration for git-server
This script will set Autopilot rule to to auto expand the PVCs when the usage reach the specified limit in percentage.
Here are the steps:
### 1. Set the configuration variables:
Edit the **config-vars** file to set the variables. Here is the description about each variable:
	
**NAMESPACE_MATCH_LABEL:** Provide the namespace label. Autopilot will filter the namespaces based on this label and will take the actions only on the PVCs which exist in those namespaces.
**PVC_MATCH_LABEL:** Provide the PVC label. Autopilot will take the actions on the PVCs which match this label.
**VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION:** Set the limit in percentage, so Autopilot can take the specified action once this limit is reached. 
**SCALE_PERCENTAGE:** Provide the amount of space in percentage to expand when the usage limit is reached.
**VOLUME_MAX_SIZE:** Provide the maximum size limit so the Autopilot can stop further expansion of the volumes. If this limit is reached Autopilot will take no more actions to expand the volumes.

Here is the sample file with all the variables set:

	  PVC_MATCH_LABEL="k8s-app=git-server"
	  NAMESPACE_MATCH_LABEL="k8s-app=git-server"
	  VOLUME_USAGE_PERCENTAGE_TO_TRIGGER_THE_ACTION="50"
	  SCALE_PERCENTAGE="50"
	  VOLUME_MAX_SIZE="30Gi"



### 2. Run the script.

Call the script as follows:

	./setup-autopilot-rule.sh
This will create a rule for Autopilot.

### 3. Fillup PVCs for testing

Call the script as follows to fill up the PVC. 'springboot-java' is the namespace the script will fill the PVCs for.
	./workload.sh springboot-java
