#!/bin/bash

echo "Converting environment variables to Java properties"
IFS=$'\\n'

echo "" >> /usr/local/unifiedviews/config/frontend-config.properties
echo "" >> /usr/local/unifiedviews/config/backend-config.properties
if [ ! -f "/usr/local/unifiedviews/.settings_set" ];
then
    printenv | grep -P "^UV_" | while read setting
    do
	key=`echo "$setting" | grep -o -P "^UV_[^=]+" | sed 's/^.\{3\}//g' | sed 's/_/./g' | awk '{print tolower($0)}'`
	value=`echo "$setting" | grep -o -P "=.*$" | sed 's/^=//g'`
	echo "Registering $key to be $value"
	echo "$key=$value" >> /usr/local/unifiedviews/config/frontend-config.properties
	echo "$key=$value" >> /usr/local/unifiedviews/config/backend-config.properties
    done
    touch /usr/local/unifiedviews/.settings_set
fi
echo "Finished converting environment variables to Java properties"

