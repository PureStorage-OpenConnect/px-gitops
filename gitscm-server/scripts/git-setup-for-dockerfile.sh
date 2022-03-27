#!/bin/bash
set -e -u
set -o pipefail
cd /home/git/repos
ls -lrth
ls="$(ls | awk 'FNR==1{print $1}')"
git clone $ls dockerfile-dev > /dev/null
sleep 2
chown -R git:git /home/*
dockerfilePath="$(ls /home/git/dockerfile | awk 'FNR==1{print $1}')"
su - git -c"cp -r ~/dockerfile/$dockerfilePath/* repos/dockerfile-dev && sleep 1 && cd repos/dockerfile-dev  && git config --global user.email 'you@example.com' && git config --global user.name 'Your Name' && git add . && git commit -m 'dockerfile' 2>&1 >/dev/null && git push origin master > /dev/null"
su - git -c"rm -rf ~/repos/dockerfile-dev"
