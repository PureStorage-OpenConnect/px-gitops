# create-branch.sh

This can be used to create branch of running git-repository on local or remote cluster. It uses Portworx backup and resotore while creating the branch. It will use an s3 bucket to store the backup. S3 bucket can be any s3 compatible bucket not just the aws s3 bucket.

# Prerequisites:
  1. A running kubernets cluster (Or two if you want to create the branch on remote cluster) and their kubeconfig files.
  2. A git-server namespace containing a repository.
  3. Utilities: kubectl, git
  4. An s3 compatible bucket with credentials in hand.

**To start the deployment for the first time**

Clone the current repository using

    git clone https://github.com/PureStorage-OpenConnect/px-gitops.git

Then in your terminal change the directory

    cd px-gitops/create-branch

# Steps:

## 1. Configure the variables:

Edit the file "config-vars" and configure the variables. Here is the description of all the variables:

**Provide s3 bucket access:**

    PX_S3_ACCESS_KEY_ID:                 Your s3 bucket access key.
    PX_S3_SECRET_ACCESS_KEY:             Your s3 secret access key.
    PX_S3_BUCKET_ENDPOINT:               Bucket end-point. e.g: "http://10.21.236.202"
    PX_S3_DISABLE_SSL:                   If your s3 bucket does not support SSL, set it as true. e.g: "true"

    PX_AWS_REGION:                       Set with aws s3 bucket region. Will be ignored if bucket is not AWS s3 bucket. e.g: "us-east-2"

**Provide kubeconfig files:**

You will need to provide the kube config files of the clusters.

    PX_KUBECONF_PATH_SOURCE_CLUSTER:       Path of kube config of source cluster.
    PX_KUBECONF_PATH_DESTINATION_CLUSTER:  Path of kube config of destination cluster.

Example:

    PX_KUBECONF_PATH_SOURCE_CLUSTER="/home/myuser/.kube/PS_Rancher-cluster"
    PX_KUBECONF_PATH_DESTINATION_CLUSTER="/home/myuser/.kube/PS_vSphereVMs"

If you are going to create the branch on the same cluster or different cluster, use same kube-config for both as follows:

    PX_KUBECONF_PATH_SOURCE_CLUSTER="/home/myuser/.kube/PS_Rancher-cluster"
    PX_KUBECONF_PATH_DESTINATION_CLUSTER="/home/myuser/.kube/PS_Rancher-cluster"

You can leave these varialbe blank. This way the default kube-config that is `~/.kube/config`, will be used for both. Here is the example:

    PX_KUBECONF_PATH_SOURCE_CLUSTER=""
    PX_KUBECONF_PATH_DESTINATION_CLUSTER=""
  
**Retain portworx backup:**

    PX_KEEP_BACKUP:             Set this variable as "no" if you do not want to keep the backup after the branch is created as follows:
    
 Example:
  
    PX_KEEP_BACKUP="no"


## 2. Run script as follows to create new branch:

After configuring all the variables run the script as follows to begin the process:
  
    ./create-branch.sh [Source-repository-namespace] [Name-of-new-branch]

  Example:

    ./create-branch.sh git-repo-wp-main git-repo-wp-dev

---

## Commands

**NOTE:** For every varriable between <> you will need to replace that value with your input. For example < namespace-name > will need to be replaced with your value.

**To check the git-server deployment details(pod, deployment, replicaset, service)**


    kubectl get all -n **namespace-name**


**To check the repo-name, run this command**

    kubectl describe pods **pod-name** -n **namespace-name** | grep -A1 'Mounts:' | awk 'FNR == 2 {print}' | cut -d"/" -f5 | awk '{print $1}'

**Note:** The pod name is the name of pod displayed on output when running the "kubectl get all -n namespace-name" command above. For reference please check below screenshot.

![](./pod-details.png?raw=true "Title")

**Note**: You should have the latest version of git on your local system.

**To clone the repository, run this command**

    git clone ssh://git@**external-IP**/home/git/repos/**repo-name**

**NOTE:** The external-IP is the ip displayed on output when running the "kubectl get all -n namespace-name" command above.

**To start shell session inside the container using ssh command**


    ssh git@**external-IP**

**To start shell session inside the container using kubectl exec command**


    kubectl exec --stdin --tty **pod-name** -n **namespace-name** -- /bin/bash


## Repository Path (inside the pod)

```
/home/git/repos/<repository>
```

## Credentails

There are the default environment credentials

* Git username: git
* Git password: PureStorage123

Root user details

* username: root
* password: PureStorage123        
