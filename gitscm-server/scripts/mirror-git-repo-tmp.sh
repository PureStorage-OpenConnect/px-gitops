cd /home/git/repos
ls="$(ls | awk 'FNR==1{print $1}')"
git clone --bare https://github.com/PureStorage-OpenConnect/javaApplication-code.git
cd javaApplication-code.git
git push --mirror /home/git/repos/$ls