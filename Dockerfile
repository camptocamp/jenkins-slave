FROM ubuntu:xenial

MAINTAINER Raphaël Pinson <raphael.pinson@camptocamp.com>

ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle \
    PATH=$JAVA_HOME/bin:$PATH \
    JENKINS_SWARM_VERSION=3.3 \
    HOME=/home/jenkins-slave \
    DOCKER_VERSION=1.11.2 \
    DOCKER_COMPOSE_VERSION=1.11.2 \
    RANCHER_COMPOSE_VERSION=0.12.2

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install software-properties-common && \
    apt-get clean

RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    (echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections) && \
    apt-get install -y oracle-java8-installer oracle-java8-set-default && \
    apt-get clean

# apparmor is required to run docker server within docker container
RUN apt-get update && \
    apt-get install -y wget curl git iptables ca-certificates apparmor && \
    apt-get clean

RUN useradd -c "Jenkins Slave user" -d $HOME -m jenkins-slave
RUN curl --create-dirs -sSLo $HOME/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$JENKINS_SWARM_VERSION/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar

# We install newest docker into our docker in docker container
RUN curl -fsSLO https://get.docker.com/builds/Linux/x86_64/docker-$DOCKER_VERSION.tgz \
  && tar --strip-components=1 -xvzf docker-$DOCKER_VERSION.tgz -C /usr/local/bin \
  && chmod +x /usr/local/bin/docker \
  && rm -f docker-$DOCKER_VERSION.tgz

# Install docker compose
RUN curl -fsSLO https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-Linux-x86_64 \
    && cp docker-compose-Linux-x86_64 /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && rm -f docker-compose-Linux-x86_64

# Install rancher-compose
RUN curl -fsSLO https://github.com/rancher/rancher-compose/releases/download/v$RANCHER_COMPOSE_VERSION/rancher-compose-linux-amd64-v$RANCHER_COMPOSE_VERSION.tar.gz \
  && tar --strip-components=2 -xvzf rancher-compose-linux-amd64-v$RANCHER_COMPOSE_VERSION.tar.gz -C /usr/local/bin \
  && chmod +x /usr/local/bin/rancher-compose \
  && rm -f rancher-compose-linux-amd64-v$RANCHER_COMPOSE_VERSION.tar.gz

# Install virtualenv
RUN apt-get update && \
    apt-get install -y python-virtualenv && \
    apt-get clean

# Install basic development tools
RUN apt-get update && \
    apt-get install -y make && \
    apt-get clean

# Copy runit scripts
RUN apt-get update && \
    apt-get install -y runit && \
    apt-get clean

RUN mkdir -p /etc/service/jenkins-slave
COPY slave-run.sh /etc/service/jenkins-slave/run

ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
