This repo helps in creating the git server using shell script.

The script will perform following actions:

1) Deploy git-server (You can deploy multiple repos in single git server)
2) Mirror the entire existing git repo to the new one.

**To start the deployment for the first time**

Clone the current repository using  `git clone https://github.com/PureStorage-OpenConnect/px-gitops.git`. Then in your terminal move to the git-scm folder `cd px-gitops/gitscm-server` and run the following command  to install kustomize.

  curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

The above script detects your OS and downloads the appropriate kustomize binary to your current working directory.

**Kustomize**

Kustomize traverses a Kubernetes manifest to add, remove or update configuration options without forking. It is available both as a standalone binary and as a native feature of kubectl



**Now run the following script to deploy git-server**

```
./git-server-script.sh
```


To mirror the repository into the new repository, you can use any one from below reposiotry:

  https://github.com/PureStorage-OpenConnect/wordpress-application.git    (Contain wordpress code, Dockerfile, manifest and wp test cases)

  https://github.com/PureStorage-OpenConnect/javaApplication-code.git         (Contain java code, Dockerfile and manifest) 





## Commands

**NOTE:** Every bold text on the commands needs to be replaced with your variables. For example: If we look at the command "kubectl get all -n **namespace-name**" here we will need to replace "namespace-name" with the namespace you have created.

**To check the git-server deployment details(pod, deployment,replicaset, service)**


  kubectl get all -n **namespace-name**


**To start shell session inside the container using ssh command**


   ssh git@**external-IP**

**To start shell session inside the container using kubectl exec command**


  kubectl exec --stdin --tty **pod-name** -n **namespace-name** -- /bin/bash

---
if you receive below warning while ssh into git server or cloning the git repository. Run the following command 

> ssh-keygen -R **external-IP**


![](./add-host-key.png?raw=true "Title")

## Repository Path (inside the pod)

```
/home/git/repos/<repository>
```

## Credentails

Note: You should have the latest version of git on your local system.
There are the default environment credentials

* Git username: git
* Git password: osmium76

Root user details

* username: root
* password: osmium76

---
## Optional Command

**To clone the repository, run this command**


> git clone ssh://git@**external-IP**/home/git/repos/**repo-name**

**NOTE:** The repo name is the one you created when running the command "**./git-server-script.sh**".
The external-IP is the ip displayed on output when running the "**kubectl get all -n namespace-name**" command above.


