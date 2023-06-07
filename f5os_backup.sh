#!/bin/bash
#

name='admin'
password='admin'
ip='10.0.0.1'

# Get auth token
#
token=$(curl -D - -sk -u "$name":"$password" -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: rctoken" -X HEAD https://$ip:8888/restconf/data/openconfig-system:system/aaa |egrep '^X-Auth-Token: ' |tr -d '\r' |awk '{print $2}')

# Create backup
#
curl -vk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $token" -X POST https://$ip:8888/restconf/data/openconfig-system:system/f5-database:database/f5-database:config-backup -d '{ "f5-database:name": "Test_PoC_010123.xml" }' | jq . 

# BROKEN: Download file
#
#curl -vk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $token" https://$ip:8888/restconf/data/f5-utils-file-transfer:file/f5-file-download:download-file/f5-file-download:start-download --data-raw '{ "file-name": "Test_PoC_2.1.2.6.xml", "file-path": "configs/" }' 
#

# Download file via scp
#
scp root@$ip:/var/confd/configs/Test_PoC_010123.xml .
