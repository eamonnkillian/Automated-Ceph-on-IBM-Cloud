#!/bin/bash
#
# Created:      14-June-2019
# Author:       EJK
# Description:
#
# A short BASH script to generate the relevant host file entries for both:
#
# -> /etc/hosts; and 
# -> /etc/ansible/hosts
# 
# In the case of /etc/hosts the entries are added to the existing /etc/hosts file and 
# the /etc/ansible/hosts file is added to the newly created machines.
#
# Dependencies:
# 1) The successful creation of the virtual machines;
# 2) The successful completion of the post-installation script;
# 3) You must have an API key for the IBM Cloud account;
# 4) You must have installed the SoftLayer CLI and its Python dependencies;
# 5) You must have ssh passwordless access to the newly created IBM Cloud VSI machines.
#
# License: MIT License
# Copyright (c)2019, EJK
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# ----------------------------------------------------------------------------------------
#
#                                    BASH VARIABLES
#
# ----------------------------------------------------------------------------------------
#
DATE=`date "+%Y%m%d%H%M%S"`
OUR_MGR_IPS=`slcli vs list | grep mgr | awk '{print $3}'`
OUR_OSD_IPS=`slcli vs list | grep osd | awk '{print $3}'`
OUR_MON_IPS=`slcli vs list | grep mon | awk '{print $3}'`
MANAGER_IP=`slcli vs list | grep mgr1 | awk '{print $3}'`
ALL_IPS=$OUR_MGR_IPS" "$OUR_OSD_IPS" "$OUR_MON_IPS
POST="./post"
OUR_HOSTS="new-hosts-$DATE"
ANSIBLE_HOSTS="ansible-hosts-$DATE"

# ----------------------------------------------------------------------------------------
#
#                                       BASH SCRIPT
#
# ----------------------------------------------------------------------------------------
#

touch $POST/$OUR_HOSTS
touch $POST/$ANSIBLE_HOSTS

#
# Create /etc/ansible/hosts entries
#

echo "[mgrs]" >> $POST/$ANSIBLE_HOSTS
slcli vs list | grep mgr | awk '{print $2}' >> $POST/$ANSIBLE_HOSTS
echo "[osds]" >> $POST/$ANSIBLE_HOSTS
slcli vs list | grep osd | awk '{print $2}' >> $POST/$ANSIBLE_HOSTS
echo "[mons]" >> $POST/$ANSIBLE_HOSTS
slcli vs list | grep mon | awk '{print $2}' >> $POST/$ANSIBLE_HOSTS
echo "[mdss]" >> $POST/$ANSIBLE_HOSTS
slcli vs list | grep mds | awk '{print $2}' >> $POST/$ANSIBLE_HOSTS
echo "[rgws]" >> $POST/$ANSIBLE_HOSTS
slcli vs list | grep rgw | awk '{print $2}' >> $POST/$ANSIBLE_HOSTS

# 
# Create /etc/hosts entries
#

slcli vs list | grep mgr | awk '{print $4,$2}' >> $POST/$OUR_HOSTS
slcli vs list | grep osd | awk '{print $4,$2}' >> $POST/$OUR_HOSTS
slcli vs list | grep mon | awk '{print $4,$2}' >> $POST/$OUR_HOSTS
slcli vs list | grep mds | awk '{print $4,$2}' >> $POST/$OUR_HOSTS
slcli vs list | grep rgw | awk '{print $4,$2}' >> $POST/$OUR_HOSTS

for i in $ALL_IPS
   do
       scp $POST/$OUR_HOSTS root@$i:/tmp
       scp $POST/$ANSIBLE_HOSTS root@$i:/tmp
       ssh root@$i "cat /tmp/$OUR_HOSTS >> /etc/hosts; rm /tmp/$OUR_HOSTS"
       ssh root@$i "cat /tmp/$ANSIBLE_HOSTS >> /etc/ansible/hosts; rm /tmp/$ANSIBLE_HOSTS"
   done

for j in $ALL_IPS
   do
      ssh root@$j "ansible all -m ping"
   done

rm $POST/$OUR_HOSTS
rm $POST/$ANSIBLE_HOSTS

#
# Download Ceph-Ansible playbook and files to the Ceph Manager
#

ssh root@$MANAGER_IP "git clone https://github.com/ceph/ceph-ansible.git; cd ceph-ansible; git checkout master"
ssh root@$MANAGER_IP "cd ceph-ansible; cp site.yml.sample site.yml"

#
# Get the private network for this build - we know its a 10.x.x.x network.
# 

PRIVATE_NET=`ssh root@$MANAGER_IP "ip addr" | grep "inet 10" | awk '{print $2}'`
echo "public_network: $PRIVATE_NET" > ceph_ansible_variables
echo "cluster_network: $PRIVATE_NET" >> ceph_ansible_variables
scp ceph_ansible_variables root@$MANAGER_IP:~/ceph-ansible/group_vars/all.yml
ssh root@$MANAGER_IP "cd ~/ceph-ansible/group_vars; cat all.yml.sample >> all.yml"
scp ceph_ansible_osds_variables root@$MANAGER_IP:~/ceph-ansible/group_vars/osds.yml
ssh root@$MANAGER_IP "cd ~/ceph-ansible/group_vars; cat osds.yml.sample >> osds.yml"

exit 0

# ----------------------------------------------------------------------------------------
#
#                                          END
#
# ----------------------------------------------------------------------------------------
#
