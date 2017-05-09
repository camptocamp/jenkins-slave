#!/bin/sh

exec 2>&1

# jenkins swarm slave
JAR=`ls -1 $HOME/swarm-client-*.jar | tail -n 1`

PARAMS=""
if [ ! -z "$JENKINS_USERNAME" ]; then
  PARAMS="$PARAMS -username $JENKINS_USERNAME"
fi
if [ ! -z "$JENKINS_PASSWORD" ]; then
  PARAMS="$PARAMS -passwordEnvVariable JENKINS_PASSWORD"
fi
if [ ! -z "$SLAVE_EXECUTORS" ]; then
  PARAMS="$PARAMS -executors $SLAVE_EXECUTORS"
fi
if [ ! -z "$NODE_LABELS" ]; then
  for l in $NODE_LABELS; do
    PARAMS="$PARAMS -labels $l"
  done
fi
if [ ! -z "$SLAVE_NAME" ]; then
  PARAMS="$PARAMS -name $SLAVE_NAME"
else
  if getent hosts rancher-metadata >/dev/null; then
    SLAVE_NAME=$(curl http://rancher-metadata/latest/self/container/name)
    PARAMS="$PARAMS -name $SLAVE_NAME"
  fi
fi
if [ ! -z "$JENKINS_MASTER" ]; then
  PARAMS="$PARAMS -master $JENKINS_MASTER"
else
  if [ ! -z "$JENKINS_SERVICE_PORT" ]; then
    # kubernetes environment variable
    PARAMS="$PARAMS -master http://$SERVICE_HOST:$JENKINS_SERVICE_PORT"
  fi
fi

# Add dexcription containing all host facts for dynamic node selection in shared library groovy scripts
# example:
#
# import jenkins.model.*
# import groovy.json.JsonSlurper
#
# for (slave in jenkins.model.Jenkins.instance.slaves) {
#     labels = slave.getLabelString()
#   for (label in labels.split(" ")) {
#
#     if (label.startsWith('{"facts"')){
#     def facts = new JsonSlurper().parseText(label)
#     println facts.facts
#     }
#   }
# }
#
FACTS=$(facter --json | tr -d '[:space:]')
FACTS_LABEL="{\"facts\":${FACTS}}"
PARAMS="$PARAMS -description ${FACTS_LABEL}"

java -jar $JAR $PARAMS -fsroot $HOME
