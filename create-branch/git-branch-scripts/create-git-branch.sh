#!/bin/bash
set -e -u
set -o pipefail
cd /home/git/repos
ls="$(ls | awk 'FNR==1{print $1}')"
cd $ls
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
countbranch="$(git branch -a | wc -l)"
if [ "$countbranch" != 1 ]
then
git branch | grep -v "master" | xargs git branch -D > /dev/null 2>&1
fi
if [[ "$BRANCH" = "master" || "$BRANCH" = "main" ]]; then
#	for multipleBranch; do echo $multipleBranch && git update-ref refs/heads/$multipleBranch refs/heads/$BRANCH; done
    for branch; do echo $branch && git update-ref refs/heads/$branch refs/heads/$BRANCH; done
	git symbolic-ref HEAD refs/heads/$branch;
fi
