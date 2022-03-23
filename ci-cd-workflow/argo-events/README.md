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

**Working on Argo-events**

The Events source will for some events E.g. webhooks and right those events to the events bus. Then sensors that will listen to the events written in even bus and execute some actions or trigger some operation E.g. Argo-workflow.

In our use case, we are using webhook as Event-Source that will send the events whenever we push something to the Git repository or create a pull request. Then sensors  that are listening to those events will trigger the Argo-workflow. 

With combination of both Argo-events and Argo-worflows we have fully operational CI/CD pipeline type of solution


**Deploy Argo-events**

bash 