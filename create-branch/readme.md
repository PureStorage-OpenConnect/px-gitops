Prerequisites:
  1) Utilities: kubectl, sed, awk, grep

**To start the deployment for the first time**

Clone the current repository using  `git clone https://github.com/PureStorage-OpenConnect/px-gitops.git`. Then in your terminal move to the git-scm folder `cd px-gitops/create-branch
`
Steps: 
1)  Configure variables in "config-vars" file. Here is the description of all the variables:

  1.1 Provide aws access:
  
        PX_AWS_REGION:                        Set with aws region you want to use for s3 backup.
        PX_AWS_ACCESS_KEY_ID:                 Your aws access key.
        PX_AWS_SECRET_ACCESS_KEY:             Your aws secret access key.

      Example:
        PX_AWS_REGION="us-east-2"
        PX_AWS_ACCESS_KEY_ID="CJG4MUKD5HUUFJD6ASCL"
        PX_AWS_SECRET_ACCESS_KEY="0mZfAKIAd5dBUfF2BXqz4vP/pc0NkcTZpbiiWEwseJlc"

  1.2 Provide kubeconfig files:
  
      PX_KUBECONF_PATH_SOURCE_CLUSTER:      Path of kube config of source cluster. 
      PX_KUBECONF_PATH_DESTINATION_CLUSTER: Path of kube config of destination cluster.       

      Example:
        PX_KUBECONF_PATH_SOURCE_CLUSTER="/home/myuser/.kube/PS_Rancher"
        PX_KUBECONF_PATH_DESTINATION_CLUSTER="/home/myuser/.kube/PS_vSphereVMs"
      
      If you want to create the new repo on the same cluster, use same kube-config for both:

      Example:
        PX_KUBECONF_PATH_SOURCE_CLUSTER="/home/myuser/.kube/PS_Rancher"
        PX_KUBECONF_PATH_DESTINATION_CLUSTER="/home/myuser/.kube/PS_Rancher"

      You can leave these varialbe blank. This way the default cluster accessible by kubectl will be used as source and the destination.

      Example:
        PX_KUBECONF_PATH_SOURCE_CLUSTER=""
        PX_KUBECONF_PATH_DESTINATION_CLUSTER=""

2) Run script as follows to create new branch:
  ./create-branch.sh [Source-repository-name] [Name-of-new-repository]
  Example:
    ./create-branch.sh git-repo-wp-main git-repo-wp-dev
---

## Commands

**NOTE:** Every bold text on the commands needs to be replaced with your variables. For example: If we look at the command "kubectl get all -n **namespace-name**" here we will need to replace "namespace-name" with the namespace you have created.

**To check the git-server deployment details(pod, deployment, replicaset, service)**


> kubectl get all -n **namespace-name**


**To check the repo-name, run this command**

> kubectl describe pods **pod-name** -n **namespace-name** | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}'

**Note:** The pod name is the name of pod displayed on output when running the "kubectl get all -n namespace-name" command above. For reference please check below screenshot.

![](./pod-details.png?raw=true "Title")


**To clone the repository, run this command**

> git clone ssh://git@**external-IP**/home/git/repos/**repo-name**

**NOTE:** The external-IP is the ip displayed on output when running the "kubectl get all -n namespace-name" command above.

**To start shell session inside the container using ssh command**


> ssh git@**external-IP**

**To start shell session inside the container using kubectl exec command**


> kubectl exec --stdin --tty **pod-name** -n **namespace-name** -- /bin/bash


## Repository Path (inside the pod)

```
/home/git/repos/<repository>
```

## Credentails

There are the default environment credentials

* Git username: git
* Git password: osmium76

Root user details

* username: root
* password: osmium76        
