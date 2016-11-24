#!/usr/bin/env bash
set -e

### SETTINGS ####

# Git username password to clone NBA repo
GIT_USERNAME='AtzedeVries'
GIT_PASSWORD=''

# es settings (use different id if you don't want to join clusters)
CLUSTER_ID='demo'
ES_MEMORY_GB='1'

# Version and building
NBAV2='true'
BUILD_NBA='true'
# nba git taq or branch (not yet sure if hash works)
NBA_CHECKOUT='V2_master'
# dns records for loadbalancer. Add these plus your foating ip to your hosts file.
API_DNS_NAME='apitest.biodiversitydata.nl'
PURL_DNS_NAME='datatest.biodiversitydata.nl'

###############################
##   DO NOT MODIFY BELOW!!!  ##
###############################

. /etc/lsb-release
REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"
apt-get update >/dev/null
repo_deb_path=$(mktemp)
wget --output-document="${repo_deb_path}" "${REPO_DEB_URL}" 2>/dev/null
dpkg -i "${repo_deb_path}" >/dev/null
apt-get update >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install puppet git >/dev/null

git clone https://github.com/naturalis/puppet-nba /etc/puppet/modules/nba -b nbav2-allinone
git clone -b 0.14.0 https://github.com/elastic/puppet-elasticsearch /etc/puppet/modules/elasticsearch
git clone https://github.com/puppetlabs/puppetlabs-stdlib /etc/puppet/modules/stdlib
git clone https://github.com/puppetlabs/puppetlabs-apt /etc/puppet/modules/apt
git clone https://github.com/richardc/puppet-datacat /etc/puppet/modules/datacat
git clone https://github.com/biemond/biemond-wildfly /etc/puppet/modules/wildfly
git clone https://github.com/puppetlabs/puppetlabs-java /etc/puppet/modules/java
git clone https://github.com/jfryman/puppet-nginx /etc/puppet/modules/nginx
git clone https://github.com/puppetlabs/puppetlabs-concat /etc/puppet/modules/concat
git clone https://github.com/puppetlabs/puppetlabs-vcsrepo /etc/puppet/modules/vcsrepo
git clone https://github.com/nanliu/puppet-staging /etc/puppet/modules/staging


echo  "class {'nba::all_in_one::all':
git_username        => '"${GIT_USERNAME}"' ,
git_password        => '"${GIT_PASSWORD}"',
cluster_id          => '"${CLUSTER_ID}"',
es_memory_gb        => '"${ES_MEMORY_GB}"',
nba_checkout        => '"${NBA_CHECKOUT}"',
api_dns_name        => '"${API_DNS_NAME}"',
purl_dns_name       => '"${PURL_DNS_NAME}"',
nbav2               => "${NBAV2}",
build_nba           => "${BUILD_NBA}",
}
" > /etc/puppet/manifests/nba.pp
#waiting for other nodes to be up then run again
puppet apply /etc/puppet/manifests/nba.pp
echo "Waiting for 60 seconds to get all ES nodes in a cluster"
sleep 60
puppet apply /etc/puppet/manifests/nba.pp
echo "Done, happy whatever.."
