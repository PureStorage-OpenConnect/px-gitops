# Install Utilities

Thid document will help you to install common utilities.

## KubeCtl (v1.23.4 or later):

You can follow these steps to install kubectl as per you operating environment:

Use following command to check:

    kubectl version --client

If it is not installed use following commands to install:
	
**Linux:**
	
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl
		
**macOS:**
		
  	brew install kubectl


## StorkCtl

To install **storkctl** you must have access to a running portworx cluster through **kubectl**.

Run the following command to verify if it is already installed:

	storkctl version

If it returns version number then it is installed, else install it with following commands:
	
* 1st export **KUBECONFIG** variable with the kube config file path:

	> Make sure to replace the **< Provide-Full-Path-Of-Your-KubeConfig-File >**:

		export KUBECONFIG=<Provide-Full-Path-Of-Your-KubeConfig-File>

* Now run following commands to download the **storkctl**:

	> '**--retries**' parameter only works with kubectl v.1.23 or later (Tested with v.1.23.4). If this version is not available try without the **--retries** option, but in some cases it fails with '**unexpected EOF**' error. In that situation please upgrade kubectl.

		STORK_POD=$(kubectl get pods --all-namespaces -l name=stork -o jsonpath='{.items[0].metadata.namespace} {.items[0].metadata.name}')
		kubectl cp -n "${STORK_POD% *}"  ${STORK_POD#* }:/storkctl/$(uname -s| awk '{print tolower($0)}')/storkctl ./storkctl --retries=20
		sudo mv storkctl /usr/local/bin
		sudo chmod +x /usr/local/bin/storkctl
