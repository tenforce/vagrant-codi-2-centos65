#!/bin/bash
UV_DATABASE_SQL_USER=root
UV_DATABASE_SQL_PASSWORD=root
MASTER_USER=master
MASTER_PASSWORD=commander

chown -R tomcat7:tomcat7 /usr/local/unifiedviews
chown -R tomcat7:tomcat7 /usr/local/unifiedviews/logs
chmod +x /usr/local/unifiedviews/add-dpu.sh
chmod +x /usr/local/unifiedviews/env-to-java-properties-file.sh

sh  /usr/local/unifiedviews/env-to-java-properties-file.sh

# Unified Views backend
cd /usr/local/unifiedviews
nohup java -DconfigFileLocation=/usr/local/unifiedviews/config/backend-config.properties -jar /usr/local/unifiedviews/packages/backend-2.1.0.jar &

# Unified Views frontend
cp /usr/local/unifiedviews/packages/unifiedviews.war /usr/local/tomcat7/webapps/

# Unified Views API
cp /usr/local/unifiedviews/packages/master.war /usr/local/tomcat7/webapps/

# Start Tomcat
chmod +x /usr/local/tomcat7/bin/setenv.sh
service tomcat7 start

# Wait till Tomcat startup has finished and webapps are started (max 3 minutes)
i=0
until $(curl --output /dev/null --silent --head --fail --user $MASTER_USER:$MASTER_PASSWORD http://localhost:8080/master/api/1/pipelines) || [ "$i" -gt 36 ]; do
    i=$((i+1))
    printf '.'
    sleep 5
done

# Add DPUs
for f in /usr/local/unifiedviews/dpus/*.jar; do bash /usr/local/unifiedviews/add-dpu.sh "$f"; done

tail -f /var/log/tomcat7/catalina.out
