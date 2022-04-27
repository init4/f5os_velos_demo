#!/bin/bash
#
# https://github.com/init4/telstra_velos_demo_210422 
#  Docs: https://clouddocs.f5.com/api/velos-api/api-workflows.html 
#  j.mcinnes@f5.com
#
name="admin"
password="admin"

# Configuring tenant admin credentials
#
echo -n "- Configuring tenant admin credentials: "
ip="10.0.0.14"
curl -sk -u "$name":"$password" -H "Content-Type: application/yang-data+json" -X POST -d @pwd https://$ip:8888/restconf/operations/openconfig-system:system/aaa/authentication/users/user=admin/config/change-password
echo -n "orange"

ip="10.0.0.15"
curl -sk -u "$name":"$password" -H "Content-Type: application/yang-data+json" -X POST -d @pwd https://$ip:8888/restconf/operations/openconfig-system:system/aaa/authentication/users/user=admin/config/change-password
echo ", purple"

# Get auth token
#
password="Default12345!"
echo -n "- Getting API auth token: "
ip="10.0.0.14"
o_token=$(curl -D - -sk -u "$name":"$password" -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: rctoken" -X HEAD https://$ip:8888/restconf/data/openconfig-system:system/aaa |egrep '^X-Auth-Token: ' |tr -d '\r' |awk '{print $2}')
echo "$o_token"
ip="10.0.0.15"
p_token=$(curl -D - -sk -u "$name":"$password" -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: rctoken" -X HEAD https://$ip:8888/restconf/data/openconfig-system:system/aaa |egrep '^X-Auth-Token: ' |tr -d '\r' |awk '{print $2}')
echo "$p_token"
sleep 5

# Configuring tenant VLANs 
#
echo -n "- Configuring tenant VLANs: "
ip="10.0.0.14"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $o_token" -X PATCH -d @vlan https://$ip:8888/restconf/data/openconfig-vlan:vlans
echo -n "orange"
ip="10.0.0.15"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $p_token" -X PATCH -d @vlan https://$ip:8888/restconf/data/openconfig-vlan:vlans
echo ", purple"

# Configuring tenant network interfaces 
#
echo -n "- Configuring tenant network interfaces: "
ip="10.0.0.14"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $o_token" -X PATCH -d @portgroup_orange https://$ip:8888/restconf/data/
echo -n "orange"
ip="10.0.0.15"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $p_token" -X PATCH -d @portgroup_purple https://$ip:8888/restconf/data/
echo ", purple"

# FIXME: check the API for interfaces status 
#
echo "- Waiting for network interfaces..."
sleep 300

# Assign VLANs to the interfaces
#
echo -n "- Assigning VLANs to the interfaces: "
ip="10.0.0.14"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $o_token" -X PATCH -d @interface_orange https://$ip:8888/restconf/data/
echo -n "orange"
ip="10.0.0.15"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $p_token" -X PATCH -d @interface_purple https://$ip:8888/restconf/data/
echo ", purple"

# Copy BIGIP images to tenants
#
# curl --insecure -i -u admin:admin -X POST --header "Content-Type: application/yang-data+json" 
#   https://$ip:8888/restconf/data/f5-utils-file-transfer:file/import --d @upload
# {
#   "f5-utils-file-transfer:local-file": "images/staging/F5OS-C-${VERSION}.${IMAGE_TYPE^^}.iso"
# }
#
echo "- Copy BIGIP image to tenant... "
scp ~/BIGIP-14.1.4.6-0.0.8.T1-VELOS.qcow2.zip.bundle root@10.0.0.11:/var/F5/partition2/IMAGES
scp ~/BIGIP-15.1.5.1-0.0.14.ALL-F5OS.qcow2.zip.bundle root@10.0.0.11:/var/F5/partition2/IMAGES
scp ~/BIGIP-14.1.4.6-0.0.8.T1-VELOS.qcow2.zip.bundle root@10.0.0.11:/var/F5/partition3/IMAGES
scp ~/BIGIP-15.1.5.1-0.0.14.ALL-F5OS.qcow2.zip.bundle root@10.0.0.11:/var/F5/partition3/IMAGES

# Configuring tenant deployments
#
echo -n "- Configuring tenant deployments: "
ip="10.0.0.14"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $o_token" -X POST -d @tenant_orange https://$ip:8888/restconf/data/f5-tenants:tenants
echo -n "orange"
ip="10.0.0.15"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $p_token" -X POST -d @tenant_purple https://$ip:8888/restconf/data/f5-tenants:tenants
echo ", purple"

echo "- Leave configuration in place?"
read i
if [ "$i" != yes ]
then
echo "- Removing tenant deployments: "
ip="10.0.0.14"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $o_token" -X DELETE https://$ip:8888/restconf/data/f5-tenants:tenants/tenant=orange-bigip03-micro
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $o_token" -X DELETE https://$ip:8888/restconf/data/f5-tenants:tenants/tenant=orange-bigip04-large
echo -n "orange"
ip="10.0.0.15"
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $p_token" -X DELETE https://$ip:8888/restconf/data/f5-tenants:tenants/tenant=purple-bigip05-micro
curl -sk -H "Content-Type: application/yang-data+json" -H "X-Auth-Token: $p_token" -X DELETE https://$ip:8888/restconf/data/f5-tenants:tenants/tenant=purple-bigip06-large
echo ", purple"
else
echo "- Finished"
fi

