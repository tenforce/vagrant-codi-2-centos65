#!/bin/sh
########################################################################
# Basic installer for all the known components.

INSTALLDIR=`pwd`

########################################################################

MAVEN_VERSION=2.0.11
JAVA_VERSION=1.7.0

########################################################################
# Install maven (2.0.11 version of maven is used).

wget_n() {
    mkdir -p /vagrant/downloads
    pushd /vagrant/downloads
      wget -N $1
    popd
}

install_virtuoso() {
    pushd ${INSTALLDIR}/downloads
      git clone https://gist.github.com/10016200.git
    popd
}
    
install_maven2() {
    wget_n http://archive.apache.org/dist/maven/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
    pushd ${INSTALLDIR}/downloads
      tar xvf apache-maven-${MAVEN_VERSION}-bin.tar.gz
      cp -r apache-maven-${MAVEN_VERSION} /opt
    popd
}

install_docker() {
    yum -y remove docker
    curl -sSL https://get.docker.com/ | sh
    usermod -aG docker vagrant
    service docker start
}

install_java() {
    yum -y install yum-priorities
    yum -y install java-${JAVA_VERSION}-openjdk java-${JAVA_VERSION}-openjdk-devel
}

#################################################################
# CODI code
install_docker;
install_maven2;
install_java;
install_virtuoso;
export PATH=/opt/apache-maven-${MAVEN_VERSION}/bin:$PATH
export JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk.x86_64

( pushd ${INSTALLDIR}
    git clone https://git.tenforce.com/Paul.Massey/CODI-1.git
    pushd CODI-1
      mvn site:run -P eu-consilium-uv-documentation -Dport=9090
    popd
  popd )

