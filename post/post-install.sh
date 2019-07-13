#!/bin/bash
# 
# Created:      16-June-2019
# Author:       EJK
# Description:
#
# A short BASH script that is remotely executed on each host by Terraform as part of the host creation
# process. This script executes the following tasks straight after VM creation:
#
# 1) Create a message of the day informing admins of what type of machine this is;
# 2) Update/patch the operating system;
# 3) Install the Extra Packages for Enterprise Libraries (EPEL);
# 4) Install Ansible;
# 5) Install git.
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

IDENTIFIER=`hostname | awk '{print substr($0,0,3)}'`
case "$IDENTIFIER" in
   'mgr')
      echo "CEPH MANAGER NODE" > /etc/motd
      ;;
   'osd')
      echo "CEPH STORAGE NODE" > /etc/motd
      ;;
   'mon')
      echo "CEPH MONITOR NODE" > /etc/motd
      ;;
   'mds')
      echo "CEPH METADATA NODE" > /etc/motd
      ;;
   'rgw')
      echo "CEPH OBJECT GATEWAY NODE" > /etc/motd
      ;;   
   *)
      echo "CEPH NODE" > /etc/motd
      ;;
esac
yum -y update 
yum -y install epel-release
yum -y install ansible
yum -y install git
yum -y install python-pip
pip install netaddr
pip install notario