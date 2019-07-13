#!/bin/bash
# 
# Created:      15-June-2019
# Author:       EJK
# Description:
#
# A short BASH script to run the entire installation of Ceph. The objective is to be able to implement
# Ceph is as 'hands-free' or 'automated' a manner as possible. Automating anything as complex as a Ceph
# install does mean making some decisions in advance. This script executes the following tasks:
#
# 1) Plan a Terraform deployment (creates the Plan file)
# 2) Execute the Terraform deployment;
# 3) Add the additional requirements to support ansible;
# 4) Copy over the pre-configured Ceph Ansible configuration files:
#    
#    - ceph-ansible-variables
#    - ceph-ansible-osds-variables
#   
# 5) Run the Ceph ansible installation.
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
#                                       START SCRIPT
#
# ----------------------------------------------------------------------------------------
#

# 
# Its easy to forget to do this and these sets of scripts fail. Before running clear the local
# known_hosts file.
#

rm ~/.ssh/known_hosts
touch ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

#
# Main execution
# 

terraform plan -out create-ceph.plan
terraform apply create-ceph.plan
./ansible-additionals.sh



