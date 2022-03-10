cd /home/git/repos
ls="$(ls | awk 'FNR==1{print $1}')"
git clone --bare https://github.com/PureStorage-OpenConnect/wordpressApplication-code-and-manifest.git
cd wordpressApplication-code-and-manifest.git
git push --mirror /home/git/repos/$ls
cd ..
rm -rf wordpressApplication-code-and-manifest.git
