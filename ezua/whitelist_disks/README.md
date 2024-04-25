
# Introduction to Whitelisting disks

A user may have many disks on a node and does not want Data Fabric to use all of them.  A user can choose which disks are used by Data Fabric on each node.  This process is called whitelisting disks.  The disks that will be used on each node can be different. 

The list of disks will be provided in a text file called /mnt/whitelist.  Here is a sample: 

m2-lr1-dev-vm20.mip.storage.hpecorp.net: /dev/sdb 
m2-lr1-dev-vm21.mip.storage.hpecorp.net: /dev/sdc 
m2-lr1-dev-vm22.mip.storage.hpecorp.net: /dev/sdb,/dev/sdc 
m2-lr1-dev-vm23.mip.storage.hpecorp.net: /dev/sdd 

The whitelist file can have FQDN or IP addresses.

The file with the list of disks needs to be copied to each worker node before UA is installed.  The file must be called "whitelist" and must be placed in /mnt.  The user may need sudo privileges to place the whitelist file in /mnt.  The push_whitelist bash script is provided to push the whitelist file to each node specified in the file.  It is optional to use this script. The user can distribute the whitelist file themselves.

# Prerequisites

The bash script is designed to run on the kubernetes master node for the workload cluster.  It uses sshpass to copy the whitelist file to each worker node. Please install sshpass on the master node.

The bash script will look for a file called whitelist in the local directory and push this file to /mnt on each worker node.  Verify that the file can be read by the user running the installer.

# Usage

The bash script will prompt for a username and password that can be used to log into each worker node.

# Sample output

./push_whitelist
Enter Username : 
<username>
Enter Password :***************
node m2-lr1-dev-vm21.mip.storage.hpecorp.net: devicelist /dev/sdb
Warning: Permanently added 'm2-lr1-dev-vm21.mip.storage.hpecorp.net,10.227.21.21' (ECDSA) to the list of known hosts.
node m2-lr1-dev-vm22.mip.storage.hpecorp.net: devicelist /dev/sdc,/dev/sdc,/dev/sdc
Warning: Permanently added 'm2-lr1-dev-vm22.mip.storage.hpecorp.net,10.227.21.22' (ECDSA) to the list of known hosts.
node m2-lr1-dev-vm23.mip.storage.hpecorp.net: devicelist /dev/sdb,/dev/sdc,/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde
Warning: Permanently added 'm2-lr1-dev-vm23.mip.storage.hpecorp.net,10.227.21.23' (ECDSA) to the list of known hosts.
node m2-lr1-dev-vm24.mip.storage.hpecorp.net: devicelist /dev/sdd
Warning: Permanently added 'm2-lr1-dev-vm24.mip.storage.hpecorp.net,10.227.21.24' (ECDSA) to the list of known hosts.

# Considerations

If this file is present on a given node at installation time, it will be used to select which disks are used by Data Fabric.  If it is not present on a given node, Data Fabric will select all the available disks as it currently does, so it preserves current behavior.  Please ensure that this file is present on all nodes to get the desired result. 

If a disk is listed for a node, but the disk is not present on the node, the disk is ignored.  If all the disks for a node are not valid, the node will not use any disk for Data Fabric storage.  This could cause an installation failure if the node is selected for Data Fabric storage.  Every node needs to have at least one disk available for Data Fabric storage.  The user must be careful when specifying disks in the file. 

If this file is present on a node, and the node is not listed in the file, then all disks on the node are ignored.  The node will not use any disk for Data Fabric storage.  This could cause an installation failure if the node is selected for Data Fabric storage.  Every node needs to have at least one disk available for Data Fabric storage.  The user must be careful to include all nodes in the file. 

Disks will be checked for size.  Disks must be 500 GB or larger.  Prechecks performs a similar check, so this check may be redundant.
