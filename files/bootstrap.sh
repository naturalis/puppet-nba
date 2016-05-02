#!/usr/bin/env bash
set -e
### SETTINGS ####
GIT_USERNAME='AtzedeVries'
GIT_PASSWORD=''
CLUSTER_ID='demo'
ES_REPLICAS='0'
ES_MEMORY_GB='1'
NBA_CHECKOUT='v0.15'

### do not modify beyond ###
#$cluster_id   = 'demo',
#$es_replicas  = '0',
#$es_memory_gb = '1',
#$nba_checkout = 'v0.15',

. /etc/lsb-release
REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"
apt-get update >/dev/null
repo_deb_path=$(mktemp)
wget --output-document="${repo_deb_path}" "${REPO_DEB_URL}" 2>/dev/null
dpkg -i "${repo_deb_path}" >/dev/null
apt-get update >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install puppet git >/dev/null

git clone https://github.com/naturalis/puppet-nba /etc/puppet/modules/nba -b feature/biemondwildfly
git clone https://github.com/elastic/puppet-elasticsearch /etc/puppet/modules/elasticsearch
git clone https://github.com/puppetlabs/puppetlabs-stdlib /etc/puppet/modules/stdlib
git clone https://github.com/puppetlabs/puppetlabs-apt /etc/puppet/modules/apt
git clone https://github.com/richardc/puppet-datacat /etc/puppet/modules/datacat
git clone https://github.com/biemond/biemond-wildfly /etc/puppet/modules/wildfly -b v0.5.1
git clone https://github.com/puppetlabs/puppetlabs-java /etc/puppet/modules/java
git clone https://github.com/jfryman/puppet-nginx /etc/puppet/modules/nginx
git clone https://github.com/puppetlabs/puppetlabs-concat /etc/puppet/modules/concat
git clone https://github.com/puppetlabs/puppetlabs-vcsrepo /etc/puppet/modules/vcsrepo


puppet apply -e "class {'nba::all_in_one::all': git_username => '"${GIT_USERNAME}"' , git_password => '"${GIT_PASSWORD}"' }"
#waiting for other nodes to be up then run again
sleep 120
puppet apply -e "class {'nba::all_in_one::all': git_username => '"${GIT_USERNAME}"' , git_password => '"${GIT_PASSWORD}"' }"
