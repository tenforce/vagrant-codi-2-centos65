#!/bin/bash
########################################################################
# Basic installer for all the known UV components.

set -x 

INSTALLDIR=`pwd`

########################################################################

UV_DATABASE_SQL_USER=root
UV_DATABASE_SQL_PASSWORD=root
MASTER_USER=master
MASTER_PASSWORD=commander
DOWNLOAD_ALLOWED=yes

########################################################################

UV_VERSION=2.1.0
UV_PLUGINS_VERSION=2.1.0

JAVA_VERSION=1.7.0
MAVEN_VERSION=3.3.9
TOMCAT_VERSION=7.0.65

########################################################################
# Download function which will using the -N option make sure that the
# download is only done once and will be placed in the downloads directory

wget_n() {
    mkdir -p ${INSTALLDIR}/downloads
    pushd ${INSTALLDIR}/downloads
      # Reduce the number of attempts since it will be used off-line
      wget -N -t 2 $1
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
    if [ ! -d "/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64" ]
    then
	yum -y install yum-priorities
	yum -y install java-${JAVA_VERSION}-openjdk java-${JAVA_VERSION}-openjdk-devel
	# Add to path setting
	echo "export JAVA_HOME=\"/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64\"" >> ${HOME}/.bashrc
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
# Note: as far as possible, put everything in standard Linux 
# locations for the sys-admin. 

download_uv() {
    pushd ${INSTALLDIR}/downloads
       # Use to docker jar, war, etc.
       git clone https://github.com/tenforce/docker-unified-views
       # Missed Jars
       wget_n http://central.maven.org/maven2/com/jcraft/jsch/0.1.53/jsch-0.1.49.jar
       # DB schema
       wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v${UV_PLUGINS_VERSION}/db/mysql/schema.sql
       wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v${UV_PLUGINS_VERSION}/db/mysql/data-core.sql
       wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v${UV_PLUGINS_VERSION}/db/mysql/data-permissions.sql
       wget_n https://dl.dropboxusercontent.com/u/7519106/dpus.zip
       wget_n https://dl.dropboxusercontent.com/u/7519106/dpu-lib.zip
    popd
}

#################################################################################

build_uv_plugins() {
    pushd ${INSTALLDIR}/downloads
      # The OJDBC7.JAR has to be manually downloaded from oracle site (sorry)
      mvn install:install-file -Dfile=/vagrant/downloads/ojdbc7.jar -DgroupId=com.oracle \
	  -DartifactId=ojdbc7 -Dversion=12.1.0.2.0 -Dpackaging=jar

      mkdir -p dpus
      pushd dpus
        unzip ../dpus.zip
      popd
      mkdir -p dpu-lib
      pushd dpu-lib
        unzip ../dpu-lib.zip
      popd
	
      # Now copy the jars to where they are supposed to be before installing
      mkdir -p /usr/local/unifiedviews/dpus
      cp dpus/*.jar /usr/local/unifiedviews/dpus
      cp dpu-lib/*.jar /usr/local/tomcat7/lib
      cp jsch-0.1.49.jar /usr/local/tomcat7/lib 
      cp dpu-lib/*.jar /usr/local/unifiedviews/lib
      cp jsch-0.1.49.jar /usr/local/unifiedviews/lib 
    popd
}

#################################################################################

create_mysql_tables() {
    echo "create_mysql_tables"
    echo "create database unifiedviews; use unifiedviews" | mysql -u root -proot
    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/schema.sql
    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/data-core.sql
    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/data-permissions.sql
}

#################################################################################

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

#################################################################################

install_uv() {
    source ~/.bashrc
    if [ ! -d "/usr/local/unifiedviews" ]
    then
	# Directories to dump everything
	mkdir -p /usr/local/unifiedviews
        mkdir -p /usr/local/unifiedviews/dpus
	mkdir -p /usr/local/unifiedviews/logs
	mkdir -p /usr/local/unifiedviews/dpu
	mkdir -p /usr/local/unifiedviews/config
	mkdir -p /usr/local/unifiedviews/lib
	mkdir -p /usr/local/unifiedviews/backend/working
	 
	build_uv_plugins
	# Create the necessary tables
	create_mysql_tables
	
	pushd /usr/local/unifiedviews
         touch logs/frontend.log logs/frontend_err.log
	 cp -r ${INSTALLDIR}/downloads/docker-unified-views/packages .
	 cp ${INSTALLDIR}/config-files/*.properties config
	 cp ${INSTALLDIR}/config-files/startup.sh .
	 cp ${INSTALLDIR}/config-files/add-dpu.sh .
	 cp ${INSTALLDIR}/config-files/env-to-java-properties-file.sh .
	 cp -r ${INSTALLDIR}/downloads/docker-unified-views/packages/lib /usr/local/unifiedviews
         create_uv_service;
	 echo "Starting Service"
	 chmod +x /usr/local/unifiedviews/startup.sh
	 /usr/local/unifiedviews/startup.sh
        popd
    fi
}

#################################################################

install_mail() {
    if ! hash mail 2>/dev/null; then
	yum -y install mailutils sendmail
    fi
}

#################################################################
# CODI-2
#################################################################

if [ "$DOWNLOAD_ALLOWED" = "yes" ]
then
    download_tomcat7;
    download_maven3;
    download_uv
fi

if [ ! -f "downloads/ojdbc7.jar" ] ; then
    echo "Error: ojdbc7.jar must be downloaded from Oracle website"
    ecit -1;
fi

install_default;            # Main component installs
install_webbrowser;
install_editor;
install_java;
install_maven3;
install_tomcat7;
install_mysql;
# install_mail;
install_uv                  # Anything to do with Unified-Views

#################################################################
exit 0;
#################################################################
