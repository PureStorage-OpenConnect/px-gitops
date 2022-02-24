apt install curl -y &&
mkdir -p /home/git/.ssh
cp /root/.ssh/* /home/git/.ssh
cp /root/.ssh/id_rsa.pub /home/git/.ssh/authorized_keys
for dir in /home/git/repos/*; do(git init --bare "$dir"); done
chown -R git:git /home/*
