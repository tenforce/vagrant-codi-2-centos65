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
chmod -R a+w /usr/local/unifiedviews/dpu
chmod -R a+w /usr/local/unifiedviews/lib
cd /usr/local/unifiedviews
service unifiedviews-backend start
# export JAVA_OPTS="-verbose:gc  -XX:+PrintGCDetails -XX:+PrintGCTimeStamps" 
# nohup java -DconfigFileLocation=/usr/local/unifiedviews/config/backend-config.properties -jar /usr/local/unifiedviews/packages/backend-2.?.0.jar &

# Unified Views frontend
cp /usr/local/unifiedviews/packages/unifiedviews.war /usr/local/tomcat7/webapps/

# Unified Views API
cp /usr/local/unifiedviews/packages/master.war /usr/local/tomcat7/webapps/

# Start Tomcat
echo "Tomcat: Starting"
chmod +x /usr/local/tomcat7/bin/setenv.sh
service tomcat7 start
echo "Tomcat: Started"

# Wait till Tomcat startup has finished and webapps are started (max 3 minutes)
echo "Wait for webapps to startup"
i=0
until $(curl --output /dev/null --silent --head --fail --user $MASTER_USER:$MASTER_PASSWORD http://localhost:8080/master/api/1/pipelines) || [ "$i" -gt 36 ]; do
    i=$((i+1))
    printf '.'
    sleep 5
done

echo "Done ... loading DPUs"

# Add DPUs
for f in /usr/local/unifiedviews/dpus/*.jar;
do
    bash /usr/local/unifiedviews/add-dpu.sh "$f";
done

tail -f /usr/local/tomcat7/logs/catalina.out
