# NBA: All in one documentation

#### What all_in_one does
* Created a instance with
  * elasticsearch
  * wildfly
  * nba api
  * nba import
  * nba export
  * purl
  * loadbalancer
  * kibana
* Automaticly joins into a cluster

#### What all_in_one does not
* Insert data into ES (not yet)
* Install Admin interface (not yet)
* Replicate export zips over nodes (not yet)
* Bring cofee (not yet..)

#### Quickstart
This will launch a 3 cluster setup:

1. Log into stack.naturalis.nl
2. Create a new instance
3. Give a name
4. Set count to 3
5. Select ubuntu 14.04 Image
6. Select network
7. Select security groups (more on this futher)
8. Add your public key
9. Add bootstrap script to the configuration
  10. The script can be found here: https://raw.githubusercontent.com/naturalis/puppet-nba/feature/biemondwildfly/files/bootstrap.sh
  11. Change setting of
    12. GIT_USERNAME to your github username
    13. GIT_PASSWORD to your github password
10. Launch and wait 5 minutes.
11. You can check progress in the log tab of the instances
12. Log into the instance with ubuntu@your-floating-ip
13. Log into sense with http://floating-ip:5601/app/sense
14. Goto http://floatingip/v0/version
15. Goto http://floatingip:8080/(v0 or purl)

#### Security group
For this to work, create a security group with the following rules. You only have to do this once.
* (rule) HTTP (remote) CIDR (cidr) 0.0.0.0/0
* (rule) SSH (remote) CIDR (cidr) 0.0.0.0/0
* (rule) Custom TCP Rule (direction) Ingress (Open port) port (port) 8080 (remote) CIDR (cidr) 0.0.0.0/0
* (rule) Custom TCP Rule (direction) Ingress (Open port) port (port) 5601 (remote) CIDR (cidr) 172.16.0.0/16
* (rule) Custom TCP Rule (direction) Ingress (Open port) port  (port) -1 (remote) Security Group (Security grout) <name of your security group> (ether type) IPV4
* (rule) Custom UDP Rule (direction) Ingress (Open port) port  (port) -1 (remote) Security Group (Security grout) <name of your security group> (ether type) IPV4
* (rule) Custom CMDP Rule (direction) Ingress (Type) -1  (Code) -1 (remote) Security Group (Security grout) <name of your security group> (ether type) IPV4



#### Settings in bootstrap.sh
The boostrap has the following settings
```
GIT_USERNAME='AtzedeVries'
GIT_PASSWORD=''
```
Your github username and password to clone the naturalis_data_api repository
```
CLUSTER_ID='demo'
```
ID of your cluster. Keep this the same if you want the cluster to join. Change this if you want differnt clusters
```
ES_MEMORY_GB='1'
```
Memory heap of ES, change this to half of the size of RAM of instance for best performance
```
NBA_CHECKOUT='v0.15'
```
Github branch or tag to use (not yet tested  with hash)
```
API_DNS_NAME='apitest.biodiversitydata.nl'
PURL_DNS_NAME='datatest.biodiversitydata.nl'
```
DNS records at which the loadbalancer listens. You can add these to your hosts file in combination with the floating ip.

## Setup examples
This will describe how to make the following setups
* Two instances with two different clusters
* Create one elasticsearch cluster with multiple versions of NBA

#### Two different clusters
1. Launch a instance. Add the scirpt and change `CLUSTER_ID` to `CLUSTER_ID=demo-1`
2. Launch a instance. Add the scirpt and change `CLUSTER_ID` to `CLUSTER_ID=demo-2`

#### One ES cluster, different versions
1. Launch a instance. Add the scirpt and change `NBA_CHECKOUT` to `NBA_CHECKOUT=v0.15`
2. Launch a instance. Add the scirpt and change `NBA_CHECKOUT` to `NBA_CHECKOUT=v0.15.1`
3. Access the different versions via floating ip's on 8080 port number

## Handy extra's

#### Add volume storage to instance to have extra harddrive space
This is usefull when importing large amounts of data.

1. Create volume
2. attach it to the instance
3. Log in and

  ```
  sudo -s
  mkfs.ext4 /dev/vdb
  mkdir /storage
  mount /dev/vdb /storage
  mkdir /storage/import
  ln -s /storage/import /data/import
  ```

#### Remove elasticsearch node from cluster
Run the following `PUT` request where the ip address is the IP to the fo be removed node.
```
PUT _cluster/settings  {
  "transient" :{
      "cluster.routing.allocation.exclude._ip" : "10.0.0.1"
   }
}
```
