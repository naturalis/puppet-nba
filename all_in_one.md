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
8. Add your keypair
9. Add bootstrap script to the configuration
  10. The script can be found here: https://raw.githubusercontent.com/naturalis/puppet-nba/feature/biemondwildfly/files/bootstrap.sh
  11. Change setting of
    12. GIT_USERNAME to your github username
    13. GIT_PASSWORD to your github password
10. Launch and wait 5 minutes.
11. You can check progress in the log tab of the instances
12. Log into the instance with ubuntu@your-floating-ip
13. Log into sense with http://floating-ip:5601/app/sense

#### Security group
For this to work, create a security group with the following rules. You only have to do this once.
* (rule) HTTP (remote) CIDR (cidr) 0.0.0.0/0
* (rule) SSH (remote) CIDR (cidr) 0.0.0.0/0
* (rule) Custom TCP Rule (direction) Ingress (Open port) port (port) 8080 (remote) CIDR (cidr) 0.0.0.0/0
* (rule) Custom TCP Rule (direction) Ingress (Open port) port (port) 5601 (remote) CIDR (cidr) 172.16.0.0/16
* (rule) Custom TCP Rule (direction) Ingress (Open port) port  (port) -1 (remote) Security Group (Security grout) <name of your security group> (ether type) IPV4
* (rule) Custom UDP Rule (direction) Ingress (Open port) port  (port) -1 (remote) Security Group (Security grout) <name of your security group> (ether type) IPV4
* (rule) Custom CMDP Rule (direction) Ingress (Type) -1  (Code) -1 (remote) Security Group (Security grout) <name of your security group> (ether type) IPV4