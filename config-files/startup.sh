#!/bin/bash

: ${UV_DATABASE_SQL_USER:=root}
: ${UV_DATABASE_SQL_PASSWORD:=root}
: ${MASTER_USER:=master}
: ${MASTER_PASSWORD:=commander}
: ${ACCOUNT:=unifiedviews}

chown -R ${ACCOUNT}:${ACCOUNT} /usr/local/unifiedviews
chown -R ${ACCOUNT}:${ACCOUNT} /usr/local/unifiedviews/logs
chmod +x /usr/local/unifiedviews/add-dpu.sh
chmod +x /usr/local/unifiedviews/env-to-java-properties-file.sh

sh  /usr/local/unifiedviews/env-to-java-properties-file.sh

# Unified Views backend
echo "**** Info: startup the backend (will create database schema)"
chmod -R a+w /usr/local/unifiedviews/dpu
chmod -R a+w /usr/local/unifiedviews/lib
cd /usr/local/unifiedviews
service unifiedviews-backend start

# Unified Views frontend
cp /usr/local/unifiedviews/packages/unifiedviews.war /usr/local/tomcat7/webapps/

# Unified Views API
cp /usr/local/unifiedviews/packages/master.war /usr/local/tomcat7/webapps/

# Start Tomcat
echo "**** INFO: Tomcat: Starting"
chmod +x /usr/local/tomcat7/bin/setenv.sh
service tomcat7 start
echo "**** INFO: Tomcat: Started"

# Wait till Tomcat startup has finished and webapps are started (max 3 minutes)
echo "**** INFO: Wait for webapps to startup"
i=0
until $(curl --output /dev/null --silent --head --fail --user $MASTER_USER:$MASTER_PASSWORD http://localhost:8080/master/api/1/pipelines) || [ "$i" -gt 36 ]; do
    i=$((i+1))
    printf '.'
    sleep 5
done

echo "**** INFO: loading DPUs"

# Add DPUs
for f in /usr/local/unifiedviews/dpus/*.jar;
do
    bash /usr/local/unifiedviews/add-dpu.sh "$f";
done

echo "**** INFO: DPUs loaded"
