root@bla:~# . /etc/lsb-release
root@bla:~# REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"
root@bla:~# apt-get update >/dev/null
root@bla:~# repo_deb_path=$(mktemp)
root@bla:~# wget --output-document="${repo_deb_path}" "${REPO_DEB_URL}" 2>/dev/null
root@bla:~# dpkg -i "${repo_deb_path}" >/dev/null
root@bla:~# apt-get update >/dev/null
root@bla:~# DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install puppet >/dev/null
apt-get install git
root@bla:~# cd /etc/puppet/modules/
root@bla:/etc/puppet/modules# git clone https://github.com/naturalis/puppet-nba nba -b feature/biemondwildfly
root@bla:/etc/puppet/modules# git clone https://github.com/elastic/puppet-elasticsearch elasticsearch
root@bla:/etc/puppet/modules# git clone https://github.com/puppetlabs/puppetlabs-stdlib stdlib
root@bla:/etc/puppet/modules# git clone https://github.com/puppetlabs/puppetlabs-apt apt
root@bla:/etc/puppet/modules# git clone https://github.com/richardc/puppet-datacat datacat
root@bla:/etc/puppet/modules# git clone https://github.com/biemond/biemond-wildfly wildfly -b d30a22afe77225235cc37f05afd3a19a285fb478
root@bla:/etc/puppet/modules# git clone https://github.com/puppetlabs/puppetlabs-java java
root@bla:/etc/puppet/modules# git clone https://github.com/jfryman/puppet-nginx nginx
root@bla:/etc/puppet/modules# git clone https://github.com/puppetlabs/puppetlabs-concat concat


 puppet apply -e "class {'nba::all_in_one::all':}"
