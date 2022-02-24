cd /home/git/repos
ls="$(ls | awk 'FNR==1{print $1}')"
git clone --bare https://gitlab.redblink.net/PureStorage/java-app-manifest.git
cd java-app-manifest.git
git push --mirror /home/git/repos/$ls