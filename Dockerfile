FROM ubuntu
MAINTAINER Eystein Måløy Stenberg <eytein.stenberg@gmail.com>

RUN apt-get -y install wget lsb-release

# install latest CFEngine
RUN wget -qO- http://cfengine.com/pub/gpg.key | apt-key add -
RUN echo "deb http://cfengine.com/pub/apt $(lsb_release -cs) main" > /etc/apt/sources.list.d/cfengine-community.list
RUN apt-get update
RUN apt-get install cfengine-community

# install cfe-docker process management policy
wget https://github.com/estenberg/cfe-docker/archive/master.zip -P /tmp/ && unzip /tmp/master.zip -d /tmp/
cp /tmp/cfe-docker-master/bin/* /var/cfengine/bin/
cp /tmp/cfe-docker-master/inputs/* /var/cfengine/inputs/
rm -rf /tmp/cfe-docker-master /tmp/master.zip

RUN apt-get -y install openssh-server apache2
RUN mkdir -p /var/run/sshd
RUN echo "root:password" | chpasswd  # need a password for ssh

ENTRYPOINT ["/var/cfengine/bin/docker_processes_run.sh"]
