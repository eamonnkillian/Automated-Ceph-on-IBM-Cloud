#
# Created:      16-May-2019
# Author:       EJK
# Description:
#
# A short Terraform script to create the IBM Cloud Classic infrastructure 
# components needed to build a small virtual machine based platform for a
# Ceph software defined storage implementation. The script itself is organised
# as follows:
# 
# - set a count variable which identifies how many virtual machines will be created;
# - set an array variable with the hostnames of the virtual machines;
# - set a variable to name the data centre where the virtual machines are to be built;
#
# Note: There have been issues with connectivity from a private only network implementation
# and the EPEL repo. So this script has failed where firewall and proxy services are not
# enabling the repo to be downloaded and installed. At present this works only when a machine
# has public network access. 
#
# Dependencies:
# 1) An IBM Cloud account with sufficient permission to instance Classic infrastructure;
# 2) An API key for the IBM Cloud account;
# 3) Create & save a unique public key on IBM Cloud that will be imprinted on the VSI when created
# 4) Create & save a unique private/public key pair in the "./post/" directory that will be imprinted 
#    on all the VSI's when they are created
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
#                                    TERRAFORM STARTS
#
# ----------------------------------------------------------------------------------------
#
# TERRAFORM Variables
#
# From a change control perspective this script is set up in such a way that simply changing
# these variables will deliver the changes without having to change the structure of the
# Terraform script itself.
#
#
# These two variables are critical to customise your implementation. The default or baseline
# implementation is set up for two management nodes, three storage nodes and three monitor 
# nodes. This means a total of eight virtual machines to be instanced. At present for simplicity
# these nodes are identical in terms of configuration. Editing these values dictates the size of 
# your Ceph storage cluster:
# 
#     "vsi_count" - dictates how many virtual machines to create
#     "vsi_tags"  - dictates the hostnames of the virtual machines
#

variable "vsi_count" {
  default = "11"
}

variable "vsi_tags" {
  type = "list"
  default = [ "mgr1", "osd1", "osd2", "osd3", "mon1", "mon2", "mon3", "rgw1", "rgw2", "mds1", "mds2" ]
}

#
#  The remaining variables dictate the sizes of the virtual machines. At present the machines 
#  each have 25GB operating system disk, 100GB logging disk and a 250GB storage disk.
# 
 
variable "disk_size" {
  type = "list"
  default = [ "25", "100", "250" ]
}

variable "vsi_cores" {
  default = "1"  
}

variable "vsi_memory" {
  default = "1024"
}

variable "vsi_network_speed" {
  default = "1000"
}

variable "vsi_domain" {
  default = "saasify.com"
}

variable "vsi_post_installation" {
  default = "post/post-install.sh"
}

variable "postinstallation" {
  default = "/tmp/post-install.sh"
}

variable "private_key" {
  default = "post/id_rsa"
}

variable "public_key" {
  default = "post/id_rsa.pub"
}

variable "root_private_key" {
  default = "/root/.ssh/id_rsa"
}

variable "root_public_key" {
  default = "/root/.ssh/id_rsa.pub"
}


# ----------------------------------------------------------------------------------------
#
#                                    MAIN SCRIPT BODY
#
# ----------------------------------------------------------------------------------------

data "ibm_compute_ssh_key" "public_key" {
    label = "publicMAC"
}

resource "ibm_compute_vm_instance" "vms" {
   count                = "${var.vsi_count}"
   hostname             = "${element(var.vsi_tags, count.index)}"
   domain               = "${var.vsi_domain}"
   os_reference_code    = "CENTOS_7_64"
   datacenter           = "lon06"
   network_speed        = "${var.vsi_network_speed}"
   hourly_billing       = true
   private_network_only = false
   cores                = "${var.vsi_cores}"
   memory               = "${var.vsi_memory}"
   disks                = "${var.disk_size}"
   local_disk           = false
   ssh_key_ids          = ["${data.ibm_compute_ssh_key.public_key.id}"]

   # ----------------------------------------------------------------------------------------
   #
   #                                    POST CREATION SCRIPT
   #
   # ----------------------------------------------------------------------------------------

   provisioner "file" {
      source = "${var.public_key}"
      destination = "${var.root_public_key}"
   }

   provisioner "file" {
      source = "${var.private_key}"
      destination = "${var.root_private_key}"
   }

   provisioner "file" {
      source = "${var.vsi_post_installation}"
      destination = "${var.postinstallation}"
   }

   provisioner "remote-exec" {
      inline = [
         "chmod +x ${var.postinstallation}",
         "${var.postinstallation}",
         "chmod 0600 ${var.root_private_key}",
         "cat ${var.root_public_key} >> /root/.ssh/authorized_keys",
         "echo 'StrictHostKeyChecking no' >> /root/.ssh/config"
         ]
   }

   connection {
      type = "ssh"
      user = "root"
      private_key = "${file("/Users/eamonnkillian/.ssh/id_rsa")}"
   }

}

# ----------------------------------------------------------------------------------------
#
#                                    SCRIPT FINISHES
#
# ----------------------------------------------------------------------------------------
