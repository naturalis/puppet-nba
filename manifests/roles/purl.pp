#
#
#
class  nba::roles::purl (
  $wildfly_console_password,
  $ip_of_loadbalancer = '10.42.1.192',
){

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


  # package {['git','ant','ivy','openjdk-7-jdk']:
  #   ensure => installed,
  #   before => Class['nba']
  # }

  package {'openjdk-7-jdk':
    ensure => present,
    before => Class['wildfly'],
  }

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
    mgmt_bind        => '127.0.0.1',
    users_mgmt       => {
      'wildfly' => {
        username => 'wildfly',
        password => 'wildfly'
        }
      },
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
