root@bla:~# . /etc/lsb-release
root@bla:~# REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"
root@bla:~# apt-get update >/dev/null
root@bla:~# repo_deb_path=$(mktemp)
root@bla:~# wget --output-document="${repo_deb_path}" "${REPO_DEB_URL}" 2>/dev/null
root@bla:~# dpkg -i "${repo_deb_path}" >/dev/null
root@bla:~# apt-get update >/dev/null
root@bla:~# DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install puppet >/dev/null
