#
#
#
class  nba::roles::purl (
  $wildfly_console_password,
){

  host {'api.biodiversitydata.nl':
    ip => '10.42.1.192'
  }

  file {'/opt/wildfly_deployments':
    ensure => directory,
    mode   => '0777',
    before => Class['wildfly']
  }

  file {'/etc/purl':
    ensure  => directory,
    mode    => '0750',
    require => Class['wildfly'],
    owner   => 'wildfly',
    group   => 'wildfly',
  }

  # file {'/etc/purl/purl.properties':
  #   ensure  => present,
  #   mode    => '0750',
  #   require => File['/etc/purl'],
  #   owner   => 'wildfly',
  #   group   => 'wildfly',
  #   content => template('nba/purl/purl.properties.erb')
  # }


  $logging_properties = {
    'logger.nl.naturalis.purl.level' => { value => 'DEBUG'},
    'logger.nl.naturalis.purl.useParentHandlers' => { value => true},
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

  wildfly_cli { 'SystempropertyPurlDir':
    command  => '/system-property=nl.naturalis.purl.conf.dir:add(value=/etc/purl)',
    unless   => '(result has /etc/purl) of /system-property=nl.naturalis.purl.conf.dir:read-resource',
    username => 'wildfly',
    password => 'wildfly',
  }


  # exec {'add ivy env':
  #     command => '/bin/echo \'IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/\' >> /etc/environment',
  #     unless  => '/bin/grep environment -e IVY_HOME',
  # }
  # class { 'nba':
  #   nba_cluster_id      => 'something random because of dev',
  #   console_listen_ip   => '127.0.0.1',
  #   admin_password      => $wildfly_console_password,
  #   extra_users_hash    => undef,
  #   nba_config_dir      => '/etc/nba',
  #   es_transport_port   => '9300',
  #   index_name          => 'nda',
  #   wildfly_debug       => true,
  #   wildfly_xmx         => '1024m',
  #   wildfly_xms         => '256m',
  #   wildlfy_maxpermsize => '512m',
  #   wildfly_sys_prop    => {
  #     'nl.naturalis.purl.conf.dir' => '/etc/purl'
  #   },
  #   install_java        => true,
  #   wildfly_logging     => $logging_properties,
  #   #stage               => wildfly,
  # }

  # file { '/tmp/purl.war':
  #   ensure => present,
  #   source => 'puppet:///modules/nba/purl.war',
  #   owner  => 'wildfly',
  #   group  => 'wildfly',
  #   notify => Exec['deploy or update war with purl.war'],
  # }
  #
  # exec { 'deploy or update war with purl.war':
  #   command     => '/bin/cp -f /tmp/purl.war /opt/wildfly_deployments/purl.war',
  #   require     => File['/opt/wildfly_deployments'],
  #   refreshonly => true,
  # }


}
