cfe-docker
==========

Create Docker containers with managed processes.

Docker monitors one process in each container and the container lives or dies with that process.
CFEngine-managed Docker containers solve a couple of problem areas related to this:
* It is possible to easily start multiple processes within a container, all of which will be managed automatically
* If a managed process dies, e.g. due to a bug in application code, CFEngine will start it again within 1 minute
* The container will live as long as the CFEngine scheduling daemon (cf-execd) lives


## Usage

There are three steps:

1. Install CFEngine into the container
2. Copy the CFEngine Docker process management policy into the containerized CFEngine installation
3. Start your application processes as part of the "docker run" command

The first two steps can be done as part of a Dockerfile, as follows.

```
FROM ubuntu
MAINTAINER Eystein Måløy Stenberg <eytein.stenberg@gmail.com>

RUN apt-get -y install wget lsb-release unzip

# install latest CFEngine
RUN wget -qO- http://cfengine.com/pub/gpg.key | apt-key add -
RUN echo "deb http://cfengine.com/pub/apt $(lsb_release -cs) main" > /etc/apt/sources.list.d/cfengine-community.list
RUN apt-get update
RUN apt-get install cfengine-community

# install cfe-docker process management policy
RUN wget -qO- http://cfengine.com/pub/gpg.key | apt-key add -
RUN echo "deb http://cfengine.com/pub/apt $(lsb_release -cs) main" > /etc/apt/sources.list.d/cfengine-community.list
RUN apt-get update
RUN apt-get install cfengine-community

# add commands to install application code here...

ENTRYPOINT ["/var/cfengine/bin/docker_processes_run.sh"]
```

By saving this file as Dockerfile, you can then build your container with the familiar docker build command, e.g.
```
docker build -t my_managed_app_image .
```

When this has finished, the container will take your application commands as parameters:
```
docker run -d my_managed_app_image "/etc/init.d/myapp start" "/usr/sbin/daemon"
```

In this example, myapp and daemon will be started and and managed by CFEngine.

## Example

In this example, we will install sshd and apache2.
The processes will be started and managed by CFEngine.

Input this as your Dockerfile (also available at https://github.com/estenberg/cfe-docker/blob/master/Dockerfile).

```
FROM ubuntu
MAINTAINER Eystein Måløy Stenberg <eytein.stenberg@gmail.com>

RUN apt-get -y install wget lsb-release unzip

# install latest CFEngine
RUN wget -qO- http://cfengine.com/pub/gpg.key | apt-key add -
RUN echo "deb http://cfengine.com/pub/apt $(lsb_release -cs) main" > /etc/apt/sources.list.d/cfengine-community.list
RUN apt-get update
RUN apt-get install cfengine-community

# install cfe-docker process management policy
RUN wget --no-check-certificate https://github.com/estenberg/cfe-docker/archive/master.zip -P /tmp/ && unzip /tmp/master.zip -d /tmp/
RUN cp /tmp/cfe-docker-master/cfengine/bin/* /var/cfengine/bin/
RUN cp /tmp/cfe-docker-master/cfengine/inputs/* /var/cfengine/inputs/
RUN rm -rf /tmp/cfe-docker-master /tmp/master.zip

# apache2 and openssh is just for testing purposes
RUN apt-get -y install openssh-server apache2
RUN mkdir -p /var/run/sshd
RUN echo "root:password" | chpasswd  # need a password for ssh

ENTRYPOINT ["/var/cfengine/bin/docker_processes_run.sh"]
```

Build the container:
```
docker build -t managed_image .
```

Start the container with apache2 and sshd running and managed, forwarding a port to our SSH instance:

```
docker run -p 127.0.0.1:222:22 -d managed_image "/usr/sbin/sshd" "/etc/init.d/apache2 start"
```

We can now log in to our new container, and see that both apache2 and sshd are running:

```
ssh -p222 root@127.0.0.1

# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 07:48 ?        00:00:00 /bin/bash /var/cfengine/bin/docker_processes_run.sh /usr/sbin/sshd /etc/init.d/apache2 start
root        18     1  0 07:48 ?        00:00:00 /var/cfengine/bin/cf-execd -F
root        20     1  0 07:48 ?        00:00:00 /usr/sbin/sshd
root        32     1  0 07:48 ?        00:00:00 /usr/sbin/apache2 -k start
www-data    34    32  0 07:48 ?        00:00:00 /usr/sbin/apache2 -k start
www-data    35    32  0 07:48 ?        00:00:00 /usr/sbin/apache2 -k start
www-data    36    32  0 07:48 ?        00:00:00 /usr/sbin/apache2 -k start
root        93    20  0 07:48 ?        00:00:00 sshd: root@pts/0 
root       105    93  0 07:48 pts/0    00:00:00 -bash
root       112   105  0 07:49 pts/0    00:00:00 ps -ef
```

If we stop apache2, it will be started again within a minute by CFEngine.

```
# /etc/init.d/apache2 status
Apache2 is running (pid 32).
# /etc/init.d/apache2 stop
 * Stopping web server apache2                                                                                                                         /usr/sbin/apache2ctl: 87: ulimit: error setting limit (Operation not permitted)
apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.0.1 for ServerName
 ... waiting                                                                                                                                    [ OK ]
# /etc/init.d/apache2 status
Apache2 is NOT running.
# ... wait up to 1 minute...
# /etc/init.d/apache2 status
Apache2 is running (pid 173).
```
