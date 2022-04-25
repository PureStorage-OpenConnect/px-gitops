**Prerequisites:**

1) Argocd (To deploy the application to Kubernetes cluster)

2) Argo Workflows (To run CI pipeline)

3) Argo Events (It helps to trigger k8s objects e.g. Argo workflows)

4) Argocd-image-updater (Is a tool to automatically update the container images of Kubernetes workloads which are managed by Argo CD)

5) Argo CLI

---
**To start the deployment for the first time**

Clone the current repository using  `git clone https://github.com/PureStorage-OpenConnect/px-gitops.git`. Then in your terminal move to the ci-cd-workflow folder `cd px-gitops/ci-cd-workflow/scripts`.


**Step 1:** (Install Prerequisites)

**Install Argocd, Argo-workflows and Argo-events**
```
./install-Argo-applications.sh
```
* Run the following command to check the status of argocd

   > kubectl get all -n argocd

*  Log in to Argo CD

   Open a browser to the Argo CD external UI, and login by visiting the IP/hostname in a browser.
   
   **UserName**: admin
   
   **Password**: Run the following command to retrieve password
   
   > kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo 
   
  
* Run the following command to check the status of argo and the public URL for the Argo server UI.

   > kubectl get all -n argo

* The public URL will be returned by this command in the EXTERNAL-IP column.

* Now open a browser and navigate to: https://{YOUR_EXTERNAL_IP}:2746

* Run the following command to check the status of argo-events

   > kubectl get all -n argo-events

**Install Argo CLI**
```
https://github.com/argoproj/argo-workflows/releases
```
---

**Step: 2**

Add details of application code and manifest

Before running the script you should have the below details of application Git repo with you:

1) Namespace of main branch repository
2) Kubeconfig path of main branch repository
3) Namespace of dev branch repository
4) Kubeconfig path of dev branch repository

```
./add-details.sh
```
---

**Step: 3**

**Deploy the application using Argocd**

Before running the script you should have the below details:-

1) Application docker image name without image tag

```
./applicationDeployment.sh
```

---

**The script will perform the following actions**

* **Deploy Git Credentials**

ArgoCD Image Updater needs access to your infrastructure repository if you are using a private repository to have to set up access for Argocd.

Repository manifest template location: 
> argocd/manifests-template/application-repo-secret-tmp.yaml 


* **Deploy Image Repository Credentials.**

As our Kubernetes pods use container images stored in a private registry, the ArgoCD image updater needs read access to it in order to be able to list the different tags of the image.

Image Repository Credentials Manifest location: 
> argocd/manifest/jfrog-credentials.yaml 


*  **Add registry configuration in default Configmap of ArgoCD Image Updater.**

In the default Configmap of image updater, you need to add the registry configuration.

Registry Configuration manifest: 
> argocd/manifest/jfrog-registry-configmap.yaml 


*  **Setup ArgoCD application manifest with credentials**


Now, it will add a few annotations in the ArgoCD application. Here are the basic ones:

annotations:
```
 argocd-image-updater.argoproj.io/write-back-method: git:secret:<secret-namespace>/<your-secret-name>
 argocd-image-updater.argoproj.io/image-list: <alias>=<registry-url>
```
The first annotation tells ArgoCD to be declarative, i.e. it will commit an override file.
By default, the annotation value in ArgoCD is the imperative mode. Here we prefer the declarative way, so our repository is our only **source of truth for the state of the
cluster.**

The second annotation tells the image updater which image in which registry it should watch for updates and gives it an alias.
The <**secret-namespaces**> and <**your-secret-name**> here are the references to the secret that was created by the script in the **Deploy Git Credentials** part earlier.

ArgoCD application manifest: 
> argocd/manifests-template/application-deployment-template.yaml 

---

**Step: 4**

**Deploy Workflow Template**

**Summary**:

**Argo**

Argo specifically developed for kubernetes and integates with through CRD's(Custom Resource Definition's). Its defines the new CRD which is the **'Workflow'**. 

In workflow you define what needs to happen by laying out steps in a yaml format. Each steps runs in its own **Docker container** on kubernetes cluster. 

The workflow has metadata which consists of a **name OR generateName.** This will be the prefix of the name of the pods in which your workflow steps will run.

It is possible to define **volumes**, like you would specify those in an ordinary kubernetes context. They can be used in the templates you define after.

We can also define template which will hold other templates which we did in this case.

**For Example:**

Here we have created two workflow templates for dev and master branch for springboot java application

**Argo-workflow path**

Dev-Branch: 
> ./argo-worflow/java-app/workflow-templates/clusterworkflowtemplate-for-dev.yaml 

Master-Branch: 

> ./argo-worflow/java-app/workflow-templates/clusterworkflowtemplate-for-master.yaml 

We have defined a `ci-pipeline-to-automate-build-and-namespace-backup` template which is the entrypoint. This template contains multiple steps, which in turn are all other templates.

Each template tasks will run in its own Docker container, fully utilizing kubernetes cluster.

Here we are using four templates

1) **application-unit-testing**: will do unit testing of code, create jar file and push jar file to jfrog artifactory.

2) **pvc-snapshot**: after the unit testing passed as (its depends upon template application-unit-testing), it will create snapshot of git repository server pvc using px `Volumesnapshot.`

3) **build-docker-image**: It also depends upon template application-unit-testing. it will build and push docker image to jfrog docker registry.

4) **pvc-snapshot-restore**: If the template application-unit-testing failed, then it will restore previous snapshot using px `VolumeSnapshotRestore`.

---

As we are using application i.e. java and wordpress. We have to run separate scripts to deploy wordflow template for both.

**To submit the workflow template for the first time**

First change directory to **argo-workflow**, now you can see two application directorries i.e. `java-app` and `wordpress-app`. Now change directory in any of two applicaton-directory for which you want to submit wordlflow template.

**Note:** Before running the below script, make you should have the workflow template ready according to your application requirement.

**Run below script to deploy wordkflow template for java application**

```
./submit-java-workflow-template.sh
```

**Run below script to deploy wordkflow template for wordpress application**

```
./submit-wordpress-workflow-template.sh
```
---

**Step: 5**

**Deploy Event-Source**

**Summary**


**Argo Events**  is an event-driven workflow automation framework for Kubernetes which helps you trigger K8s objects, Argo Workflows, Serverless workloads, etc. on events from a variety of sources like webhooks, S3, schedules, messaging queues, gcp pubsub, sns, sqs, etc.

Main components of Argo Events are:

1) **Event Source**: The resource specifies how to consume events from external services such as Webhooks.
     
   The Event Source process runs within a pod managed by the eventsource-controller. The process writes to the eventbus when it observes events which match the filtering criteria.

   The EventSourceController creates deployment with port exposed and creates a service which forwards the port to Event Source pod on port.

   A service account with [List, Watch] permissions is required for the Event Source to monitor Kubernetes resources.

2) **Event Bus**: An Event Bus is a transport service for events to go from an Event Source to a Sensor. The Event Bus process runs in a cluster of three pods managed by the eventbus-controller.

3) **Sensors**: It specifies the events to look for on the Event Bus and the response to trigger when a matching event is observed.

   The sensor process runs in a pod managed by the sensor-controller.
   A service account with sufficient permissions is required if the trigger manipulates Kubernetes Objects.

**Working of Argo-events**

The Events source will look for some events E.g. webhooks and write those events to the events bus. Then sensors will listen to the events written in event bus and execute some actions or trigger some operation E.g. Argo-workflow.

In our use case, we are using webhook as Event-Source that will send the events whenever we push something to the Git repository or create a pull request. Then sensors  that are listening to those events will trigger the Argo-workflow. 

With combination of both Argo-events and Argo-worflows we have a fully operational CI/CD pipeline type of solution

**Run below script to deploy Argo-events**

```
./deploy-event-source.sh
```
---

**Note: To deploy another application repeat the steps from Step No. 2**
