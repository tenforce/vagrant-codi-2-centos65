#!/bin/bash
########################################################################
# Basic installer for all the known UV components (assuming a centos 6.5
# system). 
#
# Environment variables which can be set are:
#
#   DOWNLOAD_ALLOWED ("yes", "no")
#
#   DB_CONNECTION ("mysql","mssql")
#
set -x

INSTALLDIR=`pwd`

########################################################################
# Environment variables which have basic defaults.

: ${DOWNLOAD_ALLOWED:="yes"}
: ${DB_CONNECTION:="mysql"}
: ${MAVEN_OPTS:="-Xms256m -Xmx1024m -XX:PermSize=256m"}

  ######################################################################
  # Account details used throughout the system (change when needed)

: ${UV_DATABASE_SQL_USER:=root}
: ${UV_DATABASE_SQL_PASSWORD:=root}
: ${MASTER_USER:=master}
: ${MASTER_PASSWORD:=commander}

  ######################################################################

export DOWNLOAD_ALLOWED DB_CONNECTION MAVEN_OPTS

########################################################################
# Assume connected to the Internet and that files can be 
# downloaded as needed. 

MAVEN_REPO_LOCAL=${INSTALLDIR}/downloads/repository
MAVEN_OFFLINE=
if [ "${DOWNLOAD_ALLOWED}" = "no" ] ; then
    MAVEN_OFFLINE="-o"
fi

########################################################################

UV_VERSION=2.3.0
UV_PLUGINS_VERSION=2.2.1

########################################################################

JAVA_VERSION=1.7.0
MAVEN_VERSION=3.3.9
TOMCAT_VERSION=7.0.67

########################################################################

MUSERNAME=$1
MPASSWORD=$2
MSERVER=smtp.gmail.com

########################################################################

check_installed() {
    if ! hash $1 2>/dev/null; then
	echo "ERROR: $1 is not installed"
	exit -1;
    fi
}

########################################################################
# Download function which will using the -N option make sure that the
# operation is only done once and will be saved in the downloads directory

wget_n() {
    mkdir -p ${INSTALLDIR}/downloads
    pushd ${INSTALLDIR}/downloads
      # Reduce the number of attempts since it will be used off-line
      if ! wget -N -t 2 $1 ;
      then
	  echo "*** Error: failed to download - $1"
	  exit -1;
      fi
    popd
}

########################################################################
# install function for the set of default tools, editor and browser

install_default() {
    if ! hash git 2>/dev/null; then
	yum -y install curl git dos2unix autoconf make wget gawk bison m4
    fi
}

install_editor() {
    if ! hash emacs 2>/dev/null; then
	yum -y install emacs vim
    fi
}

install_webbrowser() {
    if ! hash firefox 2>/dev/null; then
	yum -y install firefox
    fi
}

########################################################################

install_java() {
    if [ -f "downloads/jdk-7u80-linux-x64.rpm" ]
    then
	rpm -Uvh downloads/jdk-7u80-linux-x64.rpm
	echo "export JAVA_HOME=/usr/java/jdk1.7.0_80/jre" >> /etc/environment
	echo "export JRE_HOME=/usr/java/jdk1.7.0_80/jre" >> /etc/environment	
    elif [ -d "/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64" ]
    then
	echo "*** INFO: java version installed okay"
    else
	# Assume an update will be required.
	yum -y install java-${JAVA_VERSION}-openjdk-devel
	# Add to path setting
	echo "export JAVA_HOME=\"/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64\"" >> ${HOME}/.bashrc
	echo "export JRE_HOME=\"/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64\"" >> ${HOME}/.bashrc	
	echo "export JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64" >> /etc/environment
	echo "export JRE_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64" >> /etc/environment	
        if  [ ! -d "/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64" ]
	then
	    echo "*** ERROR: failed to setup Java - download from Oracle"
	    exit -1;
	fi
    fi
}

########################################################################
# Install maven3 (version required by Unified Views).

download_maven3() {
    wget_n http://apache.cu.be/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
}

install_maven3() {
    if [ ! -d "/opt/apache-maven-${MAVEN_VERSION}" ]
    then
	pushd ${INSTALLDIR}/downloads
	  tar xvf apache-maven-${MAVEN_VERSION}-bin.tar.gz
	  cp -r apache-maven-${MAVEN_VERSION} /opt
	  # Add to path setting
	  echo "export PATH=\"/opt/apache-maven-${MAVEN_VERSION}/bin:$PATH\"" >> ${HOME}/.bashrc
        popd
    fi
    echo "/opt/apache-maven-${MAVEN_VERSION}/bin"
}

########################################################################
# Install Tomcat7 (version required by Unified Views).
# Notes: http://tecadmin.net/steps-to-install-tomcat-server-on-centos-rhel/

download_tomcat7() {
    wget_n http://www.us.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
}

install_tomcat7() {
    if [ ! -d "/usr/local/tomcat7" ]
    then
	pushd /usr/local
	  tar xvf ${INSTALLDIR}/downloads/apache-tomcat-${TOMCAT_VERSION}.tar.gz
	  mv apache-tomcat-${TOMCAT_VERSION} tomcat7
	  cp ${INSTALLDIR}/config-files/tomcat-users.xml /usr/local/tomcat7/conf
	popd
    fi
}

#################################################################

install_mysql() {
    if ! hash mysql 2>/dev/null; then
	yum -y install mysql-server
	# Start service, set the default password and enable for reboot restart
	/sbin/service mysqld start
	/usr/bin/mysqladmin -u root password root
	chkconfig mysqld on
    fi
    # Service needs to be running for unified-views to create tables, etc.
    service mysqld restart
}

#################################################################
# Download all the required parts for UV.

download_uv() {
    pushd ${INSTALLDIR}/downloads
       wget_n https://github.com/UnifiedViews/Core/archive/release/UV_Core_v2.3.0.zip
       wget_n https://github.com/UnifiedViews/Plugins/archive/release/UV_Plugins_v2.2.1.zip
       wget_n https://github.com/UnifiedViews/Plugin-DevEnv/archive/master.zip
       if [ ! -d "Core-release-UV_Core_v2.3.0" ]
       then
	   unzip -o UV_Core_*.zip
	   # otherwise the .scss file is looked for which isn't present
	   touch Core-release-UV_Core_v2.3.0/frontend/src/main/webapp/VAADIN/themes/ModTheme/styles.css
	   # Replace the updated files
	   # Update to "FOR UPDATE"
	   cp downloads/updated-java/DbScheduleImpl.java Core-release-UV_Core_v2.3.0/commons-app/src/main/java/cz/cuni/mff/xrg/odcs/commons/app/scheduling/DbScheduleImpl.java

	   cp downloads/updated-java/DbExecutionServerImpl.java Core-release-UV_Core_v2.3.0/commons-app/src/main/java/cz/cuni/mff/xrg/odcs/commons/app/execution/server/DbExecutionServerImpl.java

	   cp downloads/updated-java/ExecutionServer.java Core-release-UV_Core_v2.3.0/commons-app/src/main/java/cz/cuni/mff/xrg/odcs/commons/app/execution/server/ExecutionServer.java

	   unzip -o UV_Plugins*.zip
	   unzip -o master*.zip
       else
	   echo "*** Info: has all been unpacked previously"
       fi
       
       # Use to docker jar, war, etc.
       git clone https://github.com/tenforce/docker-unified-views
       # Missed Jars
       wget_n http://central.maven.org/maven2/com/jcraft/jsch/0.1.49/jsch-0.1.49.jar
       
       if [ "${DB_CONNECTION}" = "mysql" -a "${UV_VERSION}" = "2.1.0" ] ;
       then
	  # 2.3.0 version doesn't need this since backend does it.
	  # DB schema
	  wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v${UV_PLUGINS_VERSION}/db/mysql/schema.sql
	  wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v${UV_PLUGINS_VERSION}/db/mysql/data-core.sql
	  wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v${UV_PLUGINS_VERSION}/db/mysql/data-permissions.sql
	  wget_n https://dl.dropboxusercontent.com/u/7519106/dpus.zip
	  wget_n https://dl.dropboxusercontent.com/u/7519106/dpu-lib.zip
       fi
    popd
}

#################################################################
# save everything which might be needed for building UV offline.

save_uv_downloads() {
    pushd ${INSTALLDIR}/downloads
    if [ -d "Core-release-UV_Core_v2.3.0" ]
    then
	# Only do this at present for the 2.3.0 version of unified views
	for i in Plugin-DevEnv-master Core-release-UV_Core_v2.3.0 Plugins-release-UV_Plugins_v2.2.1
	do
            pushd $i
   	     mvn dependency:go-offline -Dmaven.repo.local=${MAVEN_REPO_LOCAL}
	    popd
	done
    fi
    popd
}
    
#################################################################
# Note: as far as possible, put everything in standard Linux 
# locations for the sake of the sys-admin. 

install_oracle_jar() {
    pushd ${INSTALLDIR}/downloads
      # The OJDBC7.JAR has to be manually downloaded from oracle site (sorry)
      # DPU required parts downloaded, unpack where needed.
      mvn -Dmaven.repo.local=${MAVEN_REPO_LOCAL} ${MAVEN_OFFLINE} \
          install:install-file -Dfile=${INSTALLDIR}/downloads/ojdbc7.jar \
	  -DgroupId=com.oracle -DartifactId=ojdbc7 -Dversion=12.1.0.2.0 \
	  -Dpackaging=jar
    popd
}

# Add the extra jdbc driver jar (pom for the backend also updated).

install_mssqlserver_jar() {
    pushd ${INSTALLDIR}/downloads
      # The sql*.tar,gz has to be manually downloaded from the ms site
      if [ "${DB_CONNECTION}" = "mssql" ]
      then
	  mkdir packages/lib
	  if [ ! -f "sqljdbc_6.0.6629.101_enu.tar.gz" ]
	  then
	      echo "*** ERROR: sqljdbc_6.0.6629.101_enu.tar.gz needs to be downloaded"
	      exit -1;
	  fi
	  tar xvf sqljdbc_6.0.6629.101_enu.tar.gz
	  cp sqljdbc_6.0/enu/sqljdbc41.jar packages/lib
	  # YUK (would be much better elsewhere)
	  cp sqljdbc_6.0/enu/sqljdbc41.jar /usr/local/tomcat7/lib
	  chown tomcat7.tomcat7 /usr/local/tomcat7/lib/sqljdbc41.jar
	  # Also make available for any build operations
	  mvn -Dmaven.repo.local=${MAVEN_REPO_LOCAL} ${MAVEN_OFFLINE} \
              install:install-file -Dfile=${INSTALLDIR}/downloads/sqljdbc_6.0/enu/sqljdbc41.jar \
	      -DgroupId=com.microsoft.sqlserver -DartifactId=sqljdbc41 -Dversion=4.1 \
	      -Dpackaging=jar
	  # Overwrite the backend pom so that it contains the ms driver jar
	  cp ${INSTALLDIR}/config-files/backend-pom.xml Core*/backend/pom.xml
      else
	  echo "*** INFO: mssql driver noy installed"
      fi
    popd
}

build_uv_plugins() {
    pushd ${INSTALLDIR}/downloads
      # Now copy the jars to where they are supposed to be before installing
      if [ "${UV_PLUGINS_VERSION}" = "2.1.0" ]
      then
	  echo "*** INFO: taking plugins from docker view"
      else
	  pushd Plugin-DevEnv-master
            mvn -Dmaven.repo.local=${MAVEN_REPO_LOCAL} ${MAVEN_OFFLINE} clean install
	  popd
	  pushd Plugins-release-UV_Plugins_v2.2.1
            mvn -DskipTests -Dmaven.repo.local=${MAVEN_REPO_LOCAL} ${MAVEN_OFFLINE} clean install
	  popd
      fi
    popd
}

build_uv_core() {
    pushd ${INSTALLDIR}/downloads    
     pushd *Core*
       mvn -Dmaven.repo.local=${MAVEN_REPO_LOCAL} ${MAVEN_OFFLINE} clean install
     popd
    
     mkdir -p packages/lib
     cp Core*/backend/target/*.jar packages
     cp -r Core*/backend/target/lib packages
     cp Core*/frontend/target/*.war packages
     cp Core*/master/target/*.war packages
     # any extras needed
     cp -r Core*/target/lib packages
    popd
}

copy_uv_plugins() {
    pushd ${INSTALLDIR}/downloads
      # Now copy the plugin jars to where they are supposed to be before installing
      mkdir -p /usr/local/unifiedviews/dpus
      mkdir -p /usr/local/unifiedviews/lib
      mkdir -p /usr/local/tomcat7/lib
      cp jsch-0.1.*.jar /usr/local/unifiedviews/lib
      cp jsch-0.1.*.jar /usr/local/tomcat7/lib	    
      if [ "${UV_PLUGINS_VERSION}" = "2.1.0" ]
      then
	  cp dpus/*.jar /usr/local/unifiedviews/dpus
	  # Update libraries where needed.
	  cp dpu-lib/*.jar /usr/local/tomcat7/lib
	  cp jsch-0.1.49.jar /usr/local/tomcat7/lib 
	  cp jsch-0.1.49.jar /usr/local/unifiedviews/lib
	  cp dpu-lib/*.jar /usr/local/unifiedviews/lib
      else
	  echo "*** INFO: Copying dpu's etc"
	  cp Plugins-release-UV_Plugins_v2.2.1/*/target/*.jar /usr/local/unifiedviews/dpus
      fi
    popd
}

#############################################################################
# Test files are where they should be (not that it works)
check_uv_installation() {
    FILES=/usr/local/tomcat7/webapps/unifiedviews.war \
	  /usr/local/tomcat7/webapps/master.war
    for f in ${FILES}
    do
	if ! -f ${f}
	then
	    echo "$f not found"
	    exit -1 ;
	fi
    done
}

##############################################################################
# Creation of the DB tables, etc. 
create_dbtables() {
    if [ "${DB_CONNECTION}" = "mysql" ]
    then
	echo "*** INFO - create mysql database needed"
	echo "create database unifiedviews; use unifiedviews" | mysql -u root -proot
	if [ "${UV_PLUGINS_VERSION}" = "2.1.0" ]
	then
	    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/schema.sql
	    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/data-core.sql
	    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/data-permissions.sql
	else
	    echo "*** INFO - db schema will be created by backend"
	fi
    else
	echo "*** INFO: tables not created yet - only for mysql/2.1.0"
    fi
}

###############################################################################

create_uv_service() {
    if [ ! -f "/etc/init.d/tomcat7" ] ; then
	cp ${INSTALLDIR}/config-files/tomcat.service /etc/init.d/tomcat7
	cp ${INSTALLDIR}/config-files/tomcat-setenv.sh /usr/local/tomcat7/bin/setenv.sh
	echo >> /etc/default/tomcat7
	sed -i "s/^TOMCAT7_USER.*/TOMCAT7_USER=root/" /etc/default/tomcat7
	sed -i "s/^TOMCAT7_GROUP.*/TOMCAT7_GROUP=root/" /etc/default/tomcat7
	groupadd tomcat7
	useradd -s /bin/bash -g tomcat7 tomcat7
	chown -Rf tomcat7.tomcat7 /usr/local/tomcat7/  
	chmod +x /etc/init.d/tomcat7
	chkconfig --add tomcat7
	chkconfig tomcat7 on
    fi
}

###############################################################################

build_uv_parts() {
    build_uv_core
    build_uv_plugins
}

install_uv() {
    echo "**** INFO: install core part of system"
    if [ ! -d "/usr/local/unifiedviews/backend/working" ]
    then
	# Directories to dump everything
	mkdir -p /usr/local/unifiedviews
        mkdir -p /usr/local/unifiedviews/dpus
	mkdir -p /usr/local/unifiedviews/logs
	mkdir -p /usr/local/unifiedviews/dpu
	mkdir -p /usr/local/unifiedviews/config
	mkdir -p /usr/local/unifiedviews/lib
	mkdir -p /usr/local/unifiedviews/backend/working

	create_dbtables
	
	pushd /usr/local/unifiedviews
         touch logs/frontend.log logs/frontend_err.log
	 if [ ! -d "${INSTALLDIR}/downloads/packages"  ] ; then
	     cp -r ${INSTALLDIR}/downloads/docker-unified-views/packages .
	     cp -r ${INSTALLDIR}/downloads/docker-unified-views/packages/lib /usr/local/unifiedviews
	 else
	     cp -r ${INSTALLDIR}/downloads/packages .
	     cp -r ${INSTALLDIR}/downloads/packages/lib /usr/local/unifiedviews
	 fi
	 if [ "$MUSERNAME" != "" ] ; then
	    cp ${INSTALLDIR}/config-files/email-config.properties ${INSTALLDIR}/config-files/email-config.properties.new
	    sed -i "s/%MAIL_PASSWORD%/$MPASSWORD/g" ${INSTALLDIR}/config-files/email-config.properties.new
	    sed -i "s/%MAIL_SERVER%/$MSERVER/g" ${INSTALLDIR}/config-files/email-config.properties.new
	 else
	     cp ${INSTALLDIR}/config-files/email-config.properties.default ${INSTALLDIR}/config-files/email-config.properties.new
	 fi
	 cat ${INSTALLDIR}/config-files/backend-config.${DB_CONNECTION}.properties ${INSTALLDIR}/config-files/email-config.properties.new > config/backend-config.properties
	 cat ${INSTALLDIR}/config-files/frontend-config.${DB_CONNECTION}.properties ${INSTALLDIR}/config-files/email-config.properties.new > config/frontend-config.properties
	 rm -f ${INSTALLDIR}/config-files/email-config.properties.new
	 cp ${INSTALLDIR}/config-files/startup.sh .
	 cp ${INSTALLDIR}/config-files/add-dpu.sh .
	 cp ${INSTALLDIR}/config-files/env-to-java-properties-file.sh .
         create_uv_service;
	 echo "Starting Service"
	 chmod +x /usr/local/unifiedviews/startup.sh
	 /usr/local/unifiedviews/startup.sh
        popd
    else
	echo "UV - Already setup"
    fi
}

##############################################################################
# Configure Postfix to be able to send an email message from the CMD Line.
#
install_mail() {
    if ! hash mail 2>/dev/null; then
	yum -y install mailutils sendmail postfix ca-certificates
    fi
}

config_mail() {
    if grep -Fq "smtp.gmail.com" /etc/postfix/main.cf
    then
	echo "PostFix already configured - do nothing"
    else
	echo "relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/postfix/cacert.pem
smtp_use_tls = yes" >> /etc/postfix/main.cf
	echo "[smtp.gmail.com]:587    ${MUSERNAME}:${MPASSWORD}" > /etc/postfix/sasl_passwd
	chmod 400 /etc/postfix/sasl_passwd
	postmap /etc/postfix/sasl_passwd
	cat /etc/ssl/certs/ca*.pem | sudo tee -a /etc/postfix/cacert.pem
	/etc/init.d/postfix reload
	echo "Test mail from postfix" | mail -s "Test Postfix" ${MUSERNAME}
    fi
}

##############################################################################
# CODI-2 (call the functions in the correct order)
##############################################################################

if [ "$DOWNLOAD_ALLOWED" = "yes" ]
then
    # Normally, this list should contain all the downloads necessary when
    # installing off-line. However, there are some problems when it comes
    # to compiling with Maven (which will also download what is required).
    #
    # The assumption is that the base box has been created, which is very
    # close to the target machine (everything can then be moved to the
    # remote machine when needed for building).
    #
    download_tomcat7;
    download_maven3;
    download_uv;
fi

if [ ! -f "downloads/ojdbc7.jar" ]
then
    echo "Error: ojdbc7.jar must be downloaded from Oracle website"
    exit -1;
fi

if [ ! -f "downloads/sqljdbc_6.0.6629.101_enu.tar.gz" ]
then
    echo "Error: sqljdbc_6.0.6629.101_enu.tar.gz must be downloaded from microsoft website"
    exit -1;
fi

if [ ! -d "${INSTALLDIR}/downloads/docker-unified-views/packages" ]
then
    echo "ERROR: downloading of components needs to be executed"
    exit -2;
fi

install_default;            # Main component installs
install_webbrowser;
install_editor;
install_java;
install_maven3
install_tomcat7

# MVN/JAVA/etc. should be accessible from this point on.
source ~/.bashrc

if [ "${DB_CONNECTION}" = "mysql" ] ; then
    install_mysql
fi

# last checks that some commands are installed
check_installed mvn
check_installed java
check_installed git

# Install some jdbc drivers

install_oracle_jar
install_mssqlserver_jar

# Start to build, configure, etc. unifiedviews

install_mail;
config_mail;
build_uv_parts;
copy_uv_plugins;
install_uv;

# It should all be installed, so final checks
check_uv_installation;
if [ "${DOWNLOADING}" = "yes" ]
then
    save_uv_downloads
fi

###############################################################################
exit 0;
###############################################################################
