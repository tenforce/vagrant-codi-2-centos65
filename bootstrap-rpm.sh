#!/usr/bin/env bash
#################################################################
yum -y install epel-release
# rpm -Uvh http://vault.centos.org/6.4/cr/x86_64/Packages/kernel-devel-2.6.32-431.el6.x86_64.rpm
yum -y install gcc gcc-c++ gmake autoconf automake flex openssl git make bzip2 perl
yum -y install kernel-devel kernel-headers dkms
yum -y groupinstall "Development Tools"
yum -y update 

#################################################################
yum -y groupinstall "Desktop" "Desktop Platform" "X Window System" "Fonts"
yum -y groupinstall "Graphical Administration Tools"
yum -y groupinstall "Internet Browser"
# yum -y groupinstall "General Purpose Desktop"

#################################################################
# Install all the alien tools which might be needed.
# rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
# rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/alien-8.90-3.el7.nux.noarch.rpm
# yum -y update && yum install alien

#################################################################
# Check boot init (change to graphical)
sed -i -e 's/:3:/:5:/g' /etc/inittab

#################################################################
# Install decent editor and some other obvious bits
yum -y install ntp ntpdate ntp-doc
chkconfig ntpd on

#################################################################
# Basic machine is present - now do the installs for the
# UV environment. Script should be the one runable on CentOS 6.x
# basic environment.

export PATH="/vagrant:${PATH}"
pushd /vagrant
 echo "****** Run the UV (CentOS 6.5) Installation Script ******"
 # install_uv_components.sh
popd

#################################################################
# Setting up the browser to reflect the development homepage.
echo "****** Setting homepage of firefox *******"
echo "user_pref(\"browser.startup.homepage\", \"file:///vagrant/homepage.html\");" >> /usr/lib64/firefox/defaults/syspref.js
echo "user_pref(\"browser.startup.homepage\", \"file:///vagrant/homepage.html\");" >> /usr/lib64/firefox/defaults/preferences/all-redhat.js

#################################################################
echo "****** Bootstraping completed ******"
#################################################################
