
# Introduction to Whitelisting disks

A user may have many disks on a node, and if the node is selected for the internal data fabric during installation, the user may not want the internal data fabric to use all of the disks for storage.  A user can choose which disks are used by the internal data fabric.  This process is called whitelisting disks.  The disks that will be used on each node can be different. 

The user will provide the list of disks in a text file called /mnt/whitelist.  These disks must be raw block devices.  Please use the disk names provided by lsblk.  Here is a sample: 

m2-lr1-dev-vm20.mip.storage.hpecorp.net: /dev/sdb  
m2-lr1-dev-vm21.mip.storage.hpecorp.net: /dev/sdc  
m2-lr1-dev-vm22.mip.storage.hpecorp.net: /dev/sdb,/dev/sdc  
m2-lr1-dev-vm23.mip.storage.hpecorp.net: /dev/sdd

The whitelist file can have FQDN or IP addresses.

The whitelist file needs to be copied to each worker node before UA is installed.  It should be copied to each worker before the UI is started.  The file must be called "whitelist" and must be placed in /mnt.  The user may need sudo privileges to place the whitelist file in /mnt.  The push_whitelist bash script is provided to push the whitelist file to each worker node specified in the file.  Please execute the push_whitelist script prior to installation.

# Prerequisites

The push_whitelist script uses sshpass to copy the whitelist file to each worker node. Please install sshpass prior to running the push_whitelist script.

The push_whitelist script will look for a file called whitelist in the local directory and push this file to /mnt on each worker node.  Verify that the file can be read by the user running the installer.

# Usage

The push_whitelist script will prompt for a username and password that can be used to log into each worker node.

./push_whitelist  
Enter Username :   
`<username>`  
Enter Password :***************  

# How it works

node m2-lr1-dev-vm20.mip.storage.hpecorp.net: devicelist /dev/sdb  
Warning: Permanently added 'm2-lr1-dev-vm20.mip.storage.hpecorp.net,10.227.20.20' (ECDSA) to the list of known hosts.  
node m2-lr1-dev-vm21.mip.storage.hpecorp.net: devicelist /dev/sdc,/dev/sdc,/dev/sdc  
Warning: Permanently added 'm2-lr1-dev-vm21.mip.storage.hpecorp.net,10.227.20.21' (ECDSA) to the list of known hosts.  
node m2-lr1-dev-vm22.mip.storage.hpecorp.net: devicelist /dev/sdb,/dev/sdc,/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde  
Warning: Permanently added 'm2-lr1-dev-vm22.mip.storage.hpecorp.net,10.227.20.22' (ECDSA) to the list of known hosts.  
node m2-lr1-dev-vm23.mip.storage.hpecorp.net: devicelist /dev/sdd  
Warning: Permanently added 'm2-lr1-dev-vm23.mip.storage.hpecorp.net,10.227.20.23' (ECDSA) to the list of known hosts.  

# Considerations

If this file is present on a node at installation time, and the node is selected by Unified Analytics for the internal data fabric, the file will be used to select which disks are used by the node.  If the file is not present on a node, the node will select all the available raw disks as it currently does, so it preserves current behavior.  Please ensure that this file is present on all worker nodes to get the desired result. 

If a disk is listed in the whitelist file for a node, but the disk is not present on the node, the disk is ignored.  If all the disks for a node are not valid, the node will not use any disk.  This could cause an installation failure if the node is selected for the internal data fabric.  Every worker node needs to have at least one raw disk.  The user must be careful when specifying disks in the file. 

If this file is present on a node, and the node is not listed in the file, then all disks on the node are ignored.  The node will not use any disk.  This could cause an installation failure if the node is selected for the internal data fabric.  Every worker node needs to have at least one raw disk.  The user must be careful to include all nodes in the file. 

Disks will be checked for size.  Disks must be 500 GB or larger.  Prechecks performs a similar check, so this check may be redundant.
