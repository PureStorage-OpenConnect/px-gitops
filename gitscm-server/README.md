This repo helps in creating the git server using shell script.

The script will perform following actions:

1) Deploy git-server (You can deploy multiple repos in single git server)
2) Mirror the entire existing git repo to the new one.

NOTE: Every bold text on the commands needs to be replaced with your variables. For example: If we look at the command "kubectl get all -n **namespace-name**" here we will need to replace "namespace-name" with the namespace you have created.

**To setup/deploy git server, run this script**

```
./git-server-script.sh
```

**To check the git-server deployment details(pod name, service, external IP)**


> kubectl get all -n **namespace-name**


**After git server is deployed/installed, run this command to clone the repository**


> ssh://git@**external-IP**/home/git/repos/**repo-name**


**To start shell session inside the container using ssh command**


> ssh git@**external-IP**

**To start shell session inside the container using kubectl exec command**


> kubectl exec --stdin --tty **pod-name** -n **namespace-name** -- /bin/bash


**Repository Path**

```
/home/git/repos
```

**Credentials**

There are the default environment credentials

* Git username: git
* Git password: osmium76

Root user details

* username: root
* password: osmium76



