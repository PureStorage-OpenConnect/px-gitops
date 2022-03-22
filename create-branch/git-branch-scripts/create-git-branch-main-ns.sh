#!/bin/bash
set -e -u
set -o pipefail
cd /home/git/repos
ls="$(ls | awk 'FNR==1{print $1}')"
cd $ls
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" = "master" || "$BRANCH" = "main" ]]; then
#	for multipleBranch; do echo $multipleBranch && git update-ref refs/heads/$multipleBranch refs/heads/$BRANCH; done
    for branch; do  git update-ref refs/heads/$branch refs/heads/$BRANCH; done
fi