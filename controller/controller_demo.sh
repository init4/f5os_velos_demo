#!/bin/bash
#
# https://github.com/init4/telstra_velos_demo_210422 
#  Docs: https://clouddocs.f5.com/api/velos-api/api-workflows.html 
#  j.mcinnes@f5.com
#
name="admin"
password="insecure"
ip="10.0.0.11"

# Get auth token
#
echo -n "- Getting API auth token: "
token=$(curl -D - -sk -u "$name":"$password" -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: rctoken" -X HEAD https://$ip:8888/restconf/data/openconfig-system:system/aaa |egrep '^X-Auth-Token: ' |tr -d '\r' |awk '{print $2}')
echo "$token"

# Release slots from the current partitions
#
echo "- Releasing slots from the current partitions"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $token" -X PATCH -d @release_default https://$ip:8888/restconf/data

# Create new partitions
#
echo "- Creating new tenant partitions"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $token" -X POST -d @partition https://$ip:8888/restconf/data/f5-system-partition:partitions

# Assign slots to the new partitions
#
echo "- Assigning slots to the new partitions"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $token" -X PATCH -d @assign_slots https://$ip:8888/restconf/data

echo "- Leave configuration in place?"
read i
if [ "$i" != yes ]
then
# Get auth token
echo -n "- Getting API auth token: "
token=$(curl -D - -sk -u "$name":"$password" -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: rctoken" -X HEAD https://$ip:8888/restconf/data/openconfig-system:system/aaa |egrep '^X-Auth-Token: ' |tr -d '\r' |awk '{print $2}')
echo "$token"

# Release slots from tenant partitions 
#
echo "- Releasing slots from the current partitions"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $token" -X PATCH -d @release_default https://$ip:8888/restconf/data

# Remove tenant partitions
#
echo "- Removing tenant partitions"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $token" -X DELETE https://$ip:8888/restconf/data/f5-system-partition:partitions/partition=orange
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $token" -X DELETE https://$ip:8888/restconf/data/f5-system-partition:partitions/partition=purple
else
echo "- Finished"
fi

