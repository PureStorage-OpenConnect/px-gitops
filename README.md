# px-gitops README

This repo helps in performing different Gitops processes using different scripts which are as follow:-

1) **Gitscm-server:** 
* Deploy git-server (You can deploy multiple repos in single git server)
* Mirror the entire existing git repo to the new one.

2) **AsyncDR:**
* Remote Site Collaboration using AsyncDR Replication.

3) **Autopilot:** 
* Here script will set Autopilot rule to to auto expand the PVCs when the usage reach the specified limit in percentage

4) **Create-branch:**
* Create branch of an existing repository (Implements PX Backup/Restore)

## Guides to perform different gitops processes.

- [Gitscm-server](https://github.com/PureStorage-OpenConnect/px-gitops/blob/main/gitscm-server/README.md)
- [AsyncDR](https://github.com/PureStorage-OpenConnect/px-gitops/blob/main/asyncDR/readme.md)
- [Autopilot](https://github.com/PureStorage-OpenConnect/px-gitops/blob/main/autopilot/readme.md)
- [Create-branch](https://github.com/PureStorage-OpenConnect/px-gitops/blob/main/create-branch/readme.md)
- [ci-cd-workflow](https://github.com/PureStorage-OpenConnect/px-gitops/blob/main/ci-cd-workflow/README.md)
