**Summary**

**Argo**

Argo specifically developed for kubernetes and integates with through CRD's(Custom Resource Definition's). Its defines the new CRD which is the **'Workflow'**. 

In workflow you define what needs to happen by laying out steps in a yaml format.Each steps runs in its own **Docker container** on kubernetes cluster. 

The workflow has metadata which consists of a **name OR generateName.** This will be the prefix of the name of the pods in which your workflow steps will run.

It is possible to define **volumes**, like you would specify those in an ordinary kubernetes context. They can be used in the templates you define after.

We can also define template which will hold other templates which we did in this case.


Here we have created two workflow templates for dev and master branch for springboot java application

**Argo-workflow path**

Dev-Branch: 
> ./workflow-templates/clusterworkflowtemplate-for-dev.yaml 

Master-Branch: 

> ./workflow-templates/clusterworkflowtemplate-for-master.yaml 

We have define a `ci-pipeline-to-automate-build-and-namespace-backup` template which is the entrypoint. This template contains multiple steps, which in turn are all other templates.

Each template tasks will run in its own Docker container, fully utilizing kubernetes cluster.

Here we are using four template

1) **application-unit-testing**: will do unit testing of code, create jar file and push jar file to jfrog artifactory.

2) **pvc-snapshot**: after the unit testing passed as (its depends upon template application-unit-testing), it will create snapshot of git repository server pvc using px `Volumesnapshot.`

3) **build-docker-image**: It also depends upon template application-unit-testing. it will build and push docker image to jfrog docker registry.

4) **pvc-snapshot-restore**: If the template application-unit-testing failed, then it will restore previous snapshot using px `VolumeSnapshotRestore`.




Deploy Argo-Workflow 
`bash submit-ci-cluster-workflow-template.sh`

