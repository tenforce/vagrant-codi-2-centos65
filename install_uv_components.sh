#!/bin/sh
########################################################################
# Basic installer for all the known UV components.

set -x 

INSTALLDIR=`pwd`
UV_DATABASE_SQL_USER=root
UV_DATABASE_SQL_PASSWORD=root
MASTER_USER=master
MASTER_PASSWORD=commander

########################################################################

JAVA_VERSION=1.7.0
MAVEN_VERSION=3.3.9
TOMCAT_VERSION=7.0.65

########################################################################
# Install maven (2.0.11 version of maven is used).

wget_n() {
    mkdir -p /vagrant/downloads
    pushd /vagrant/downloads
      wget -N $1
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

install_maven3() {
    if [ ! -d "/opt/apache-maven-${MAVEN_VERSION}" ]
    then
	wget_n http://apache.cu.be/maven/maven-3/3.3.9/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
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
install_tomcat7() {
    if [ ! -d "/usr/local/tomcat7" ]
    then
	wget_n http://www.us.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
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
	/sbin/service mysqld start
	/usr/bin/mysqladmin -u root password root
	chkconfig mysqld on
    fi
    # Service needs to be running
    service mysqld restart
}

#################################################################
# Note: as far as possible, put everything in standard Linux 
# locations for the sys-admin. 

install_uv() {
    if [ ! -d "/usr/local/unifiedviews" ]
    then
       pushd ${INSTALLDIR}/downloads
         # Use to docker jar, war, etc.
         git clone https://github.com/tenforce/docker-unified-views
         wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v2.1.0/db/mysql/schema.sql
	 wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v2.1.0/db/mysql/data-core.sql
	 wget_n https://raw.githubusercontent.com/UnifiedViews/Core/UV_Core_v2.1.0/db/mysql/data-permissions.sql
	 create_mysql_tables
       popd
       mkdir -p /usr/local/unifiedviews
       source ~/.bashrc
       pushd /usr/local/unifiedviews
         mkdir -p /usr/local/unifiedviews/dpus /usr/local/unifiedviews/logs /usr/local/unifiedviews/dpu /usr/local/unifiedviews/config
         touch logs/frontend.log logs/frontend_err.log
	 cp -r ${INSTALLDIR}/downloads/docker-unified-views/packages .
	 cp ${INSTALLDIR}/config-files/*.properties config
	 cp ${INSTALLDIR}/config-files/startup.sh .
	 cp ${INSTALLDIR}/config-files/add-dpu.sh .
	 cp ${INSTALLDIR}/config-files/env-to-java-properties-file.sh .
	 unzip -d /usr/local/unifiedviews/dpus ${INSTALLDIR}/downloads/dpus.zip
	 cp -r ${INSTALLDIR}/downloads/docker-unified-views/packages/lib /usr/local/unifiedviews
         create_uv_service;
	 /usr/local/unifiedviews/startup.sh
       popd
     fi
}

create_mysql_tables() {
    echo "create_mysql_tables"
    echo "create database unifiedviews; use unifiedviews" | mysql -u root -proot
    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/schema.sql
    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/data-core.sql
    mysql -u root -proot unifiedviews < ${INSTALLDIR}/downloads/data-permissions.sql
}

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

#################################################################
# CODI-2
#################################################################
install_default;
install_webbrowser;
install_editor;
install_java;
install_maven3;
install_tomcat7;
install_mysql;
install_uv;

#################################################################
exit 0;
#################################################################
