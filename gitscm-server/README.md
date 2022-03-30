This repo helps in creating the git server using shell script.

The script will perform following actions:

1) Deploy git-server (You can deploy multiple repos in single git server)
2) Mirror the entire existing git repo to the new one.

**To start the deployment for the first time**

Clone the current repository using  `git clone https://github.com/PureStorage-OpenConnect/px-gitops.git`. Then in your terminal move to the git-scm folder `cd px-gitops/gitscm-server` and run the following command  to install kustomize.


**Now run the following script to deploy git-server**

```
./git-server-script.sh
```


To mirror the repository into the new repository, you can use any one from below reposiotry:

  https://github.com/PureStorage-OpenConnect/wordpress-application.git    (Contain wordpress code, Dockerfile, manifest and wp test cases)

  https://github.com/PureStorage-OpenConnect/javaApplication-code.git         (Contain java code, Dockerfile and manifest) 





## Commands

**NOTE:** For every variable between <> you will need to replace that value with your input. For example kubectl get all -n < namespace-name > will need to be replaced with your value. If we call it "mynamespace" and after replacing it with your value it will look like kubectl get all -n mynamespace 

**To check the git-server deployment details(pod, deployment,replicaset, service)**


    kubectl get all -n <namespace-name>


**To start shell session inside the container using ssh command**


     ssh git@<external-IP>

**To start shell session inside the container using kubectl exec command**


     kubectl exec --stdin --tty <pod-name> -n <namespace-name> -- /bin/bash

---
if you receive below warning while ssh into git server or cloning the git repository. Run the following command 

    ssh-keygen -R <external-IP>


![](./add-host-key.png?raw=true "Title")

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

---
## Optional Command

Note: You should have the latest version of git on your local system.

**To clone the repository, run this command**


    git clone ssh://git@<external-IP>/home/git/repos/<repo-name>

**NOTE:** The repo name is the one you created when running the command "**./git-server-script.sh**".
The external-IP is the ip displayed on output when running the "**kubectl get all -n namespace-name**" command above.


