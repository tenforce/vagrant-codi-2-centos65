#!/usr/bin/env bash
#################################################################

MAVEN_VERSION=2.2.1
JAVA_VERSION=1.7.0

#################################################################
yum -y install epel-release
yum -y --enablerepo rpmforge install dkms
yum -y groupinstall "Development Tools"
yum -y install gcc gmake autoconf automake flex openssl git
yum -y install kernel-devel* kernel-headers*

#################################################################
# Sort out basic + docker installation for centos 7
# yum -y install epel-release-7
yum -y groupinstall "Desktop" "Desktop Platform" "X Window System" "Fonts"
yum -y groupinstall "Graphical Administration Tools"
yum -y groupinstall "Internet Browser"
yum -y groupinstall "General Purpose Desktop"
yum -y groupinstall "Office Suite and Productivity"
# yum -y groupinstall "Graphics Creation Tools"

# Install all the alien tools which might be needed.
rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/alien-8.90-3.el7.nux.noarch.rpm
yum update && yum install alien
     
# Check boot init (change to graphical)
sed -i -e 's/:3:/:5:/g' /etc/inittab

# Install decent editor and some other obvious bits
yum -y install dos2unix firefox emacs autoconf vim make wget curl gawk bison m4
yum -y install ntp ntpdate ntp-doc
chkconfig ntpd on

#################################################################

export PATH="/vagrant:${PATH}"
pushd /vagrant
 install_uv_components.sh;
popd

#################################################################
# Setting up the browser
echo "****** Setting homepage of firefox"
echo "user_pref(\"browser.startup.homepage\", \"file:///vagrant/homepage.html\");" >> /usr/lib64/firefox/defaults/syspref.js
echo "user_pref(\"browser.startup.homepage\", \"file:///vagrant/homepage.html\");" >> /usr/lib64/firefox/defaults/preferences/all-redhat.js

#################################################################
# finishing and cleaning up.
echo "****** Bootstraping completed"
