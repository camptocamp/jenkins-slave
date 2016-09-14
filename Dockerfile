FROM ubuntu:trusty

MAINTAINER Bilal Sheikh <bilal@techtraits.com>

RUN apt-get update && apt-get -y upgrade && apt-get -y install software-properties-common && add-apt-repository ppa:webupd8team/java -y && apt-get update

RUN (echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections) && apt-get install -y oracle-java8-installer oracle-java8-set-default

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV PATH $JAVA_HOME/bin:$PATH


# apparmor is required to run docker server within docker container
RUN apt-get update -qq && apt-get install -qqy wget curl git iptables ca-certificates apparmor

ENV JENKINS_SWARM_VERSION 2.2
ENV HOME /home/jenkins-slave


RUN useradd -c "Jenkins Slave user" -d $HOME -m jenkins-slave
RUN curl --create-dirs -sSLo $HOME/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$JENKINS_SWARM_VERSION/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar
ADD cmd.sh /cmd.sh

# set our wrapper
ENTRYPOINT ["/usr/local/bin/docker-wrapper"]

# setup our local files first
ADD docker-wrapper.sh /usr/local/bin/docker-wrapper
RUN chmod +x /usr/local/bin/docker-wrapper

# now we install docker in docker - thanks to https://github.com/jpetazzo/dind
# We install newest docker into our docker in docker container
RUN curl -fsSLO https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz \
  && tar --strip-components=1 -xvzf docker-latest.tgz -C /usr/local/bin \
  && chmod +x /usr/local/bin/docker

VOLUME /var/lib/docker

#ENV JENKINS_USERNAME jenkins
#ENV JENKINS_PASSWORD jenkins
#ENV JENKINS_MASTER http://jenkins:8080

# Install rancher-compose
ENV RANCHER_COMPOSE_VERSION 0.9.2
RUN curl -fsSLO https://github.com/rancher/rancher-compose/releases/download/v$RANCHER_COMPOSE_VERSION/rancher-compose-linux-amd64-v$RANCHER_COMPOSE_VERSION.tar.gz \
  && tar --strip-components=2 -xvzf rancher-compose-linux-amd64-v$RANCHER_COMPOSE_VERSION.tar.gz -C /usr/local/bin \
  && chmod +x /usr/local/bin/rancher-compose


# Install basic development tools
RUN apt-get install -y make

CMD /bin/bash /cmd.sh
