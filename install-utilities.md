# Install Utilities

Thid document will help you to install common utilities.

## Kubectl (v1.23.4 or later):

You can follow these steps to install kubectl as per you operating environment:

Use following command to check:

    kubectl version --client

If it is not installed use following commands to install:
	
**Linux:**
	
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	  sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl
		
**macOS:**
		
  	brew install kubectl
