#!/bin/bash
set -e -u
set -o pipefail
cd /home/git/repos
ls="$(ls | awk 'FNR==1{print $1}')"
cd $ls
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" = "master" || "$BRANCH" = "main" ]]; then
#   for multipleBranch; do echo $multipleBranch && git update-ref refs/heads/$multipleBranch refs/heads/$BRANCH; done
    for branch; do echo $branch && git update-ref refs/heads/$branch refs/heads/$BRANCH; done
    git symbolic-ref HEAD refs/heads/$branch;
    git remote add main ssh://git@XX-externalIP-XX/home/git/repos/$ls
    ssh-keyscan -t rsa XX-externalIP-XX >> ~/.ssh/known_hosts
    chown -R git:git /home/*
    git push main $branch
    git branch $BRANCH -D > /dev/null 2>&1
fi
