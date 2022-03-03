Prerequisites:
  1) Utilities: kubectl, sed, awk, grep


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