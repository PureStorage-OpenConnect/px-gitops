## Cleanup Script

Run the following script to clean up the resources

      ./cleanup-script.sh
      
## The cleanup script has three options:

**1) Clean-all-application**

This will clean all the resources created for Git-ops procress.


**2) Clean-applications-other-than-argo**

This will clean below resources from the cluster.

  * **Applications deployed using argocd**
      
  * **Git repository**
      
  * **Storage class**
  

**3) Clean-only-argo-applications**

This will clean only Argo applications
