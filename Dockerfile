FROM ubuntu
MAINTAINER Eystein Måløy Stenberg <eytein.stenberg@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "wget", "unzip", "ca-certificates"]

# install latest CFEngine
RUN wget -qO- http://cfengine.com/pub/gpg.key | apt-key add -
RUN echo "deb http://cfengine.com/pub/apt/packages stable main" > /etc/apt/sources.list.d/cfengine-community.list
RUN ["apt-get", "update"] 
RUN ["apt-get", "install", "-y", "cfengine-community"]

# install cfe-docker process management policy, from files in this directory
COPY cfengine /var/cfengine

# -- Alternately get them from another repo
#RUN wget https://github.com/estenberg/cfe-docker/archive/master.zip -P /tmp/ && unzip /tmp/master.zip -d /tmp/
#RUN cp /tmp/cfe-docker-master/cfengine/bin/* /var/cfengine/bin/
#RUN cp /tmp/cfe-docker-master/cfengine/inputs/* /var/cfengine/inputs/
#RUN rm -rf /tmp/cfe-docker-master /tmp/master.zip

# apache2 and openssh are just for testing purposes, install your own apps here
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server apache2
RUN ["apt-get", "install", "-y", "openssh-server", "apache2"]
RUN mkdir -p /var/run/sshd
RUN echo "root:password" | chpasswd  # need a password for ssh

ENTRYPOINT ["/var/cfengine/bin/docker_processes_run.sh"]

