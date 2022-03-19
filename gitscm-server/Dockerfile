FROM ubuntu:latest

RUN apt update && apt install  openssh-server tzdata- sudo vim git -y

RUN useradd -m -s /bin/bash git

RUN  echo 'git:osmium76' | chpasswd

RUN echo 'root:osmium76' | chpasswd

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN service ssh start

EXPOSE 22

CMD ["/usr/sbin/sshd","-D"]
