This repo helps in creating the git server using shell script.

The script will perform following actions:

1) Deploy git-server (You can deploy multiple repos in single git server)
2) Mirror the entire existing git repo to the new one.

Clone the current repository using  `git clone https://github.com/PureStorage-OpenConnect/px-gitops.git`. Then in your terminal move to the git-scm folder `cd px-gitops/gitscm-server` and run the following script to deploy git-server.

**To setup/deploy git server, run this script**

```
./git-server-script.sh
```

To mirror the repository into the new repository, you can use any of the one from below reposiotry

> https://github.com/PureStorage-OpenConnect/wordpressApplication-code-and-manifest.git    (Contain wordpress code, Dockerfile and manifest)

> https://github.com/PureStorage-OpenConnect/javaApplication-code.git         (Contain java code, Dockerfile and manifest) 



NOTE: Every bold text on the commands needs to be replaced with your variables. For example: If we look at the command "kubectl get all -n **namespace-name**" here we will need to replace "namespace-name" with the namespace you have created.

**To check the git-server deployment details(pod, deployment,replicaset, service, external IP)**


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



