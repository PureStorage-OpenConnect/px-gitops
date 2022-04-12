cd /home/git/repos
ls="$(ls | awk 'FNR==1{print $1}')"
git clone --bare XX-url-XX
cd XX-repo-XX
git push --mirror /home/git/repos/$ls
cd ..
rm -rf XX-repo-XX
chown -R git:git /home/*
