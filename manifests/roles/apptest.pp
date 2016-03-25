#
#
#
class  nba::roles::apptest (
  $wildfly_console_password,
){

  # file {'/opt/wildfly_deployments':
  #   ensure => directory,
  #   mode   => '0777',
  #   before => Class['nba']
  # }
  class { '::java': }

  package {['git','ant','ivy']:
    ensure => installed,
  }

  exec {'add ivy env':
      command => '/bin/echo \'IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/\' >> /etc/environment',
      unless  => '/bin/grep /etc/environment -e IVY_HOME',
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
    require            => Class['wildfly'],
    notify             => Service['wildfly'],
  }

  wildfly::config::interfaces{'public':
    inet_address_value => $::ipaddress,
    require            => Class['wildfly'],
    notify             => Service['wildfly'],
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


}
