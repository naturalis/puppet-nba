#
#
#
class  nba::roles::all()
{
  package {['git','ant','ivy']:
    ensure => installed,
  }


  file_line {'ivy_home':
    path  => '/etc/environment',
    line  => 'IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/',
    match => '^IVY_HOME',
  }

  class { '::java': }


  class { 'wildfly':
    version          => '8.1.0',
    install_source   => 'http://download.jboss.org/wildfly/8.1.0.Final/wildfly-8.1.0.Final.tar.gz',
    group            => 'wildfly',
    user             => 'wildfly',
    dirname          => '/opt/wildfly',
    java_home        => '/usr/lib/jvm/java-1.7.0-openjdk-amd64',
    java_xmx         => '1024m',
    java_xms         => '256m',
    java_maxpermsize => '512m',
    #mgmt_bind        => '127.0.0.1',
    public_bind      => $::ipaddress,
    users_mgmt       => {
      'wildfly' => {
        #username => 'wildfly',
        password => 'wildfly'
        }
      },
    require          => Class['::java']
  }

  wildfly::config::interfaces{'management':
    inet_address_value => '127.0.0.1',
    require  => Class['wildfly'],
    notify   => Service['wildfly'],
  }

  wildfly::config::interfaces{'public':
    inet_address_value => $::ipaddress,
    require  => Class['wildfly'],
    notify   => Service['wildfly'],
  }

  exec {'create nba conf dir':
    command => '/opt/wildfly/bin/jboss-cli.sh -c command="/system-property=nl.naturalis.nda.conf.dir:add(value=/etc/nba)"',
    unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls system-property" | /bin/grep nl.naturalis.nda.conf.dir',
    require => Class['wildfly'],
  }

  exec {'create nba logger':
    cwd     => '/opt/wildfly/bin',
    command => '/opt/wildfly/bin/jboss-cli.sh -c command="/subsystem=logging/logger=nl.naturalis.nda:add(level=DEBUG)"',
    unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls subsystem=logging/logger" | /bin/grep nl.naturalis.nda',
    require => Class['wildfly'],
  }

  file { '/root/.ssh':
    ensure => directory,
  }->
# Create /root/.ssh/repokeyname file
  file { '/root/.ssh/nbagit':
    ensure  => present,
    content => $repokey,
    mode    => '0600',
  }->
# Create sshconfig file
  file { '/root/.ssh/config':
    ensure  => present,
    content =>  "Host github.com\n\tIdentityFile ~/.ssh/nbagit",
    mode    => '0600',
  }->
# copy known_hosts.sh file from puppet module
  file{ '/usr/local/sbin/known_hosts.sh' :
    ensure => present,
    mode   => '0700',
    source => 'puppet:///modules/nba/known_hosts.sh',
  }->
# run known_hosts.sh for future acceptance of github key
  exec{ 'add_known_hosts' :
    command  => '/usr/local/sbin/known_hosts.sh',
    path     => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
    provider => shell,
    user     => 'root',
    unless   => 'test -f /root/.ssh/known_hosts',
  }->
# give known_hosts file the correct permissions
  file{ '/root/.ssh/known_hosts':
    mode  => '0600',
  }->

  vcsrepo { '/source/nba-git':
    ensure   => present,
    provider => git,
    source   => 'git@github.com:naturalis/naturalis_data_api.git',
    revision => $checkout,
    require  => Package['git'],
    user     => 'root',
  }

  file { '/source/nba-git/nl.naturalis.nda.build/build.properties':
    ensure  => present,
    content => template('nba/build/build.properties.erb'),
    require => Vcsrepo['/source/nba-git'],
    #notify  => Exec['build sh-config'],
  }

  exec { 'build ear':
    cwd         => '/source/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
    logoutput   => true,
    #command     => $deploy_cmd,
    command     => '/usr/bin/ant clean build-ear-file',
    refreshonly => true,
    subscribe   => [
      Vcsrepo['/source/nba-git'],
      File['/source/nba-git/nl.naturalis.nda.build/build.properties']
    ],
  }



  exec { 'deploy nba':
    cwd         => '/source/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/','PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'],
    #command     => "/usr/bin/sudo /bin/bash -c \"export IVY_HOME=${ivy_home} ;  cd /source/nba-git/nl.naturalis.nda.build ; /usr/bin/ant deploy-ear-file\"" ,
    command     => '/usr/bin/ant deploy-ear-file',
    refreshonly => true,
    require     => File['/opt/wildfly_deployments'],
    subscribe   => Exec['build ear'],
  }



  exec { 'build import':
    cwd         => '/source/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
    command     => '/usr/bin/ant clean install-import-module',
    refreshonly => true,
    subscribe   => [
      Vcsrepo['/source/nba-git'],
      File['/source/nba-git/nl.naturalis.nda.build/build.properties']
    ],
    #notify      => Exec['build sh'],
  }

  exec { 'patch-import':
    cwd         => '/source/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
    command     => '/usr/bin/ant install-import-cli',
    refreshonly => true,
    require     => Exec['build import'],
    subscribe   => File['/source/nba-git/nl.naturalis.nda.build/build.properties'],
  }

  exec { 'build export':
    cwd         => '/source/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
    command     => '/usr/bin/ant clean install-export-module',
    refreshonly => true,
    subscribe   => [
      Vcsrepo['/source/nba-git'],
      File['/source/nba-git/nl.naturalis.nda.build/build.properties']
    ],
  }
  exec { 'patch-export':
    cwd         => '/source/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
    command     => '/usr/bin/ant install-export-cli',
    refreshonly => true,
    require     => Exec['build export'],
    subscribe   => File['/source/nba-git/nl.naturalis.nda.build/build.properties'],
  }

  host {'api.biodiversitydata.nl':
    ip => $ip_of_loadbalancer,
  }

  file {'/etc/purl':
    ensure  => directory,
    mode    => '0750',
    require => Class['wildfly'],
    owner   => 'wildfly',
    group   => 'wildfly',
  }

  file {'/etc/purl/purl.properties':
    ensure  => present,
    mode    => '0750',
    require => File['/etc/purl'],
    owner   => 'wildfly',
    group   => 'wildfly',
    content => template('nba/purl/purl.properties.erb')
  }

  exec {'create purl conf dir':
    command => '/opt/wildfly/bin/jboss-cli.sh -c command="/system-property=nl.naturalis.purl.conf.dir:add(value=/etc/purl)"',
    unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls system-property" | /bin/grep nl.naturalis.purl.conf.dir',
    require => Class['wildfly'],
  }

  exec {'create purl logger':
    cwd     => '/opt/wildfly/bin',
    command => '/opt/wildfly/bin/jboss-cli.sh -c command="/subsystem=logging/logger=nl.naturalis.purl:add(level=DEBUG)"',
    unless  => '/opt/wildfly/bin/jboss-cli.sh -c command="ls subsystem=logging/logger" | /bin/grep nl.naturalis.purl',
    require => Class['wildfly'],
  }

  file { '/tmp/purl.war':
    ensure => present,
    source => 'puppet:///modules/nba/purl.war',
    owner  => 'wildfly',
    group  => 'wildfly',
    notify => Exec['deploy or update war with purl.war'],
  }

  exec { 'deploy or update war with purl.war':
    command     => '/bin/cp -f /tmp/purl.war /opt/wildfly/standalone/deployments/purl.war',
    require     => [Exec['create purl conf dir'],Exec['create purl logger']],
    refreshonly => true,
  }

}
