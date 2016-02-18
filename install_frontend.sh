#!/bin/bash
########################################################################
# Author  : P.A.Massey
# Date    : 02/02/2016
# Purpose : Installer for the CODI frontend

INSTALLDIR=`pwd`

########################################################################

: ${STAGE:="DOWNLOAD_BUILD"}

   # General environment variables which can be over-ridden

: ${MAVEN_OPTS:="-Xms256m -Xmx1024m -XX:PermSize=256m"}
: ${BUILDDIR:=frontend_build}
: ${CODI:=no}

   # Assume virtuoso/httpd server are on the same machine

: ${LOCAL_VIRTUOSO:=yes}
: ${LOCAL_HTTPD:=yes}

   # Assume virtuoso/httpd server are on the same machine

: ${LOCAL_VIRTUOSO:=yes}
: ${LOCAL_HTTPD:=yes}

   #####################################################################
   # Assume connected to the Internet and that files can be downloaded
   # as needed.

MAVEN_REPO_LOCAL=${INSTALLDIR}/downloads/repository
MAVEN_OFFLINE=
if [ "${DOWNLOAD_ALLOWED}" = "no" -o "${STAGE}" = "INSTALL_BUILT" ] ; then
    MAVEN_OFFLINE="-o"
fi

   #####################################################################

export MAVEN_OPTS

#####################################################################

JAVA_VERSION=1.7.0
MAVEN_VERSION=3.3.9
TOMCAT_VERSION=7.0.67

########################################################################
# Test that everything is installed as expected.

check_installed() {
    for i in $*
    do
	if ! hash $i 2>/dev/null; then
	    echo "ERROR: $i is not installed"
	    exit -1;
	fi
    done
}

########################################################################
# Install some standard stuff

install_editor() {
    if ! hash emacs 2>/dev/null; then
	yum -y install emacs vim
    fi
}

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
1	    exit -1;
	fi
    fi
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

########################################################################
# Install a bunch of obvious packages which might be needed.

install_basics() {
    yum -y update
    yum -y install git gcc make autoconf net-tools automake libtool \
	flex openssl bison gperf gawk m4 make openssl-devel readline-devel \
	wget rpm-build redhat-rpm-config
}

install_virtuoso_sesame() {
    pushd ${INSTALLDIR}/downloads
      mvn -Dmaven.repo.local=${MAVEN_REPO_LOCAL} ${MAVEN_OFFLINE} \
          install:install-file -Dfile=virt_sesame2.jar \
	  -DgroupId=com.openlinksw -DartifactId=virtuoso7-sesame -Dversion=2.6.10.BUILD1.12\
	  -Dpackaging=jar
    popd 
}

########################################################################

build_council() {
    pushd ${INSTALLDIR}/downloads/council-rdf-templating
      # Change the dba password (to the default used by virtuoso)
      sed -i "s/XHDxUb/dba/" src/main/webapp/WEB-INF/applicationContext.xml 
      mvn -Dmaven.repo.local=${MAVEN_REPO_LOCAL} ${MAVEN_OFFLINE} ${MAVEN_PROFILE} \
	  clean install
    popd
}

build_virtuoso() {
    check_installed automake libtool
    pushd ${INSTALLDIR}/downloads
     git clone https://github.com/nvdk/virtuoso-rpm-builder.git
     useradd rpmbuild
     mkdir -p /home/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
     echo '%_topdir /home/rpmbuild' > /home/rpmbuild/.rpmmacros
     git clone https://github.com/openlink/virtuoso-opensource.git /home/rpmbuild/virtuoso-opensource
     cp SPECS/virtuoso-opensource.spec /home/rpmbuild/SPECS/
     cp build-rpm.sh /home/rpmbuild/
     cp tf-addons/ /home/rpmbuild/virtuoso-opensource/tf-addons
     chown rpmbuild -R /home/rpmbuild
     chmod +x /home/rpmbuild/build-rpm.sh
     su rpmbuild -l -c "export VIRT_BRANCH && /home/rpmbuild/build-rpm.sh"
    popd
}

########################################################################

save_built() {
    if [ -d "${INSTALLDIR}/${BUILDDIR}" ] ; then
	rm -rf ${INSTALLDIR}/${BUILDDIR} ${INSTALLDIR}/${BUILDDIR}.*
    fi
    mkdir -p ${INSTALLDIR}/${BUILDDIR}
    pushd ${INSTALLDIR}/${BUILDDIR}
      cp ${INSTALLDIR}/install_frontend.sh .
      cp ${INSTALLDIR}/build*.sh .
      cp ${INSTALLDIR}/*.org .
      cp ${INSTALLDIR}/*.html .          
      cp -r ${INSTALLDIR}/config-files .
      cp -r ${INSTALLDIR}/downloads .
      cp -r ${INSTALLDIR}/downloads/council-rdf-templating/target/council-rdf-templating-1.0.1.war .
      cp -r ${INSTALLDIR}/data .      
      rm -rf downloads/repository
      rm -rf downloads/Core*
      rm -rf downloads/UV*
      rm -rf downloads/docker-*
    popd
    pushd ${INSTALLDIR}
     tar cvf ${BUILDDIR}.tar ${BUILDDIR}
     gzip -9 ${BUILDDIR}.tar
    popd
}

########################################################################

install_virtuoso() {
    # Ths is assuming that the virtuoso packages have been already created
    # which will required the docker to be executed and the rp files to be
    # save in the downloads directory.
    if ! hash isql-v 2>/dev/null; then
	yum install -y ${INSTALLDIR}/downloads/virtuoso-opensource-7*.rpm
    fi
}

install_saved() {
    # There should be *no* compilation from here on. Everything should be in the
    # created tar file.
    pushd ${INSTALLDIR}
     update_httpd_configuration
     mkdir -p /usr/local/tomcat7/lib    
     mkdir -p /usr/local/tomcat7/bin
     mkdir -p /usr/local/tomcat7/webapps
     cp *.war /usr/local/tomcat7/webapps
     cp downloads/virtjdbc4.jar /usr/local/tomcat7/lib
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
      service tomcat7 restart      
    popd
}

    ########################################################################
    # Update the apache httpd service

update_httpd_configuration() {
    pushd ${INSTALLDIR}    
      if [ "${LOCAL_HTTPD}" = "yes" ] ; then
	  service httpd stop
          # update the httpd service config files
          cp config-files/frontend.conf /etc/httpd/conf.d
          echo "127.0.0.1         data.consilium.europa.eu" >> /etc/hosts
	  service httpd start
      else
	  echo "*** INFO: configuration of HTTPD to proxy urls is elsewhere"
      fi
   popd
}

    ########################################################################
    # Update the local virtuoso service with default test data

update_virtuoso_data() {
    pushd ${INSTALLDIR}    
      service virtuoso-opensource stop
      # Update the virtuoso config to allow access to the /data directory
      cp -r data /
      cp config-files/virtuoso.ini /var/lib/virtuoso/db/virtuoso.ini
      service virtuoso-opensource start
      sleep 30;
      # DefaultGraph is defined in applicationContext.xml as is the
      # database location.
      #   two graphs
      #   - voting results
      #     check for browsing
      #   - everything else
      #     - entity
      #       check for merging of results
      # 
      isql-v localhost dba dba <<EOF
        ld_dir_all('/data/public_voting', '*.ttl', 'http://public_voting.codi.org');
        ld_dir_all('/data/general', '*.ttl', 'http://general.codi.org');
        rdf_loader_run();
        exit;
EOF
      # Restart the tomcat service.
    popd
}

########################################################################
#
########################################################################

if [ "$CODI" = "no" ] 
then
    install_editor
    install_maven3
    install_java
    install_tomcat7
    install_basics
fi

source ~/.bashrc

check_installed java mvn git gcc gmake autoconf chkconfig 

case "${STAGE}" in
    DOWNLOAD_BUILD)
	if [ "$CODI" = "no" ] 
        then
	    build_virtuoso
        fi
	install_virtuoso_sesame
	build_council
       ;;
    SAVE_BUILT)
	save_built
       ;;
    INSTALL_BUILT)
	install_saved
	if [ "${LOCAL_VIRTUOSO}" = "yes" ]
	then
	    install_virtuoso
	    check_installed isql-v
	    update_virtuoso_data
	else
	    echo "*** INFO: virtuoso will need to be configured applicationContext.xml"
	fi

	# Update the browser homepage to point to what is now relevant for user
	if [ "$CODI" = "no" ]
	then
	    mv /usr/share/doc/HTML/index.html /usr/share/doc/HTML/homepage_orig.html
	    cp /vagrant/homepage_frontend.html /usr/share/doc/HTML/index.html
        fi
       ;;
    *)
	echo "*** ERROR: Options are ..."
	exit -1;
esac

###############################################################################
exit 0;
###############################################################################
