#!/bin/sh

exec 2>&1

# jenkins swarm slave
JAR=`ls -1 $HOME/swarm-client-*.jar | tail -n 1`

# Disables Clients unique ID for slave name as we already have unique names with rancher
PARAMS="-disableClientsUniqueId"

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
if [ ! -z "$JENKINS_MASTER" ]; then
  PARAMS="$PARAMS -master $JENKINS_MASTER"
else
  if [ ! -z "$JENKINS_SERVICE_PORT" ]; then
    # kubernetes environment variable
    PARAMS="$PARAMS -master http://$SERVICE_HOST:$JENKINS_SERVICE_PORT"
  fi
fi

# Add a memory type label (small, medium, large)
# Also used for the slave name
mem=$(facter memorysize_mb)
if [ $(echo "0<${mem} && ${mem}<3000" | /usr/bin/bc) -eq 1 ]
then
  slave_type='small'
elif [ $(echo "3000<${mem} && ${mem}<6000" | /usr/bin/bc) -eq 1 ]
then
  slave_type='medium'
elif [ $(echo "6000<${mem} && ${mem}<12000" | /usr/bin/bc) -eq 1 ]
then
  slave_type='large'
elif [ $(echo "12000<${mem}" | /usr/bin/bc) -eq 1 ]
then
  slave_type='xlarge'
fi

# Generate slave name based on rancher container name and slave_type
if [ ! -z "$SLAVE_NAME" ]; then
  PARAMS="$PARAMS -name $SLAVE_NAME"
else
  if getent hosts rancher-metadata >/dev/null; then
    SLAVE_NAME=$(curl http://rancher-metadata/latest/self/container/name)
    PARAMS="$PARAMS -name $SLAVE_NAME-$slave_type"
  fi
fi

if [ ! -z "$slave_type" ]; then
  PARAMS="$PARAMS -labels ${slave_type}"
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
