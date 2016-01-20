#!/usr/bin/env bash
#################################################################
yum -y install dkms
# yum -y install epel-release
# yum -y install yum-plugin-priorities
# yum -y update 
yum -y groupinstall "Development Tools"
yum -y install gcc gcc-c++ gmake autoconf automake flex openssl git make bzip2 perl
yum -y install patch binutils patch libgomp glibc-headers glibc-devel dos2unix wget
yum -y install kernel-devel kernel-headers

#################################################################
# try to clear the OpenGL rebuild error (guest additions for 5.0.10)
# http://www.unixmen.com/fix-building-opengl-support-module-failed-error-virtualbox/
for i in /usr/src/kernels/2.6.32*/include/drm/
do
  pushd $i
    ln -s /usr/include/drm/drm.h drm.h
    ln -s /usr/include/drm/drm_sarea.h drm_sarea.h
    ln -s /usr/include/drm/drm_mode.h drm_mode.h
    ln -s /usr/include/drm/drm_fourcc.h drm_fourcc.h
 popd
done

#################################################################
yum -y groupinstall "Desktop" "Desktop Platform" "X Window System" "Fonts"
yum -y groupinstall "Graphical Administration Tools"
yum -y groupinstall "Internet Browser"

#################################################################
# Check boot init (change to graphical)
sed -i -e 's/:3:/:5:/g' /etc/inittab

#################################################################
yum -y install ntp ntpdate ntp-doc 
chkconfig ntpd on

#################################################################
# Basic machine is present - now do the installs for the
# UV environment. Script should be the one runable on CentOS 6.x
# basic environment.

export PATH="/vagrant:${PATH}"
pushd /vagrant
 # make sure the command files are all acceptable (not dos format)
 dos2unix *.sh config-files/*
 echo "****** Run the UV (CentOS 6.5) Installation Script ******"
 # install_uv_components.sh
popd

#################################################################
# Setting up the browser to reflect the development homepage.
echo "****** Setting homepage of firefox *******"
echo "pref(\"startup.homepage_override_url\", \"file:///vagrant/homepage.html\");" >> /usr/lib64/firefox/defaults/preferences/all-redhat.js
echo "pref(\"startup.homepage_welcome_url\", \"file:///vagrant/homepage.html\");" >> /usr/lib64/firefox/defaults/preferences/all-redhat.js

# Clean out some things (in case).
yum -y remove java

#################################################################
echo "****** Bootstraping completed ******"
#################################################################
