#
#
#
class nba::all_in_one::frameworkv2(
  $nba_cluster_name        = 'demo',
  $es_version              = '2.3.4',
  $es_repo_version         = '2.x',
  $es_shards               = '9',
  $es_replicas             = '0',
  $es_minimal_master_nodes = '1',
  $es_memory_gb            = '1'
  ) {

  package {['git','ant']:
    ensure => installed,
  }


  include apt

  apt::ppa { 'ppa:openjdk-r/ppa':
    ensure => present,
  }

  exec { 'apt-update':
    command => '/usr/bin/apt-get update',
    require => [
      Apt::Ppa['ppa:openjdk-r/ppa']
    ],
  }

  package { 'openjdk-8-jdk':
    require  => [
      Exec['apt-update'],
      Apt::Ppa['ppa:openjdk-r/ppa'],
    ],
  }

  exec {'set java-8 as default':
    command => '/usr/bin/update-java-alternatives -s java-1.8.0-openjdk-amd64',
    require => Package['openjdk-8-jdk']
  }


  class { '::wildfly':
    version          => '10.0.0',
    install_source   => 'http://download.jboss.org/wildfly/10.0.0.Final/wildfly-10.0.0.Final.tar.gz',
    group            => 'wildfly',
    user             => 'wildfly',
    dirname          => '/opt/wildfly',
    java_home        => '/usr/lib/jvm/java-1.8.0-openjdk-amd64',
    java_xmx         => '1024m',
    java_xms         => '256m',
    java_maxpermsize => '512m',
    custom_init      => 'nba/wildfly/wildfly.init.erb',
    public_bind      => $::ipaddress,
    users_mgmt       => {
      'wildfly' => {
        password => 'wildfly'
        }
      },
    require          => Package['openjdk-8-jdk']
  }

  # wildfly::config::interfaces{'management':
  #   inet_address_value => '127.0.0.1',
  #   require            => Class['::wildfly'],
  #   notify             => Service['wildfly'],
  # }
  #
  # wildfly::config::interfaces{'public':
  #   inet_address_value => $::ipaddress,
  #   require            => Class['::wildfly'],
  #   notify             => Service['wildfly'],
  # }

  exec {'create nba conf dir':
    environment => 'JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64',
    command     => '/opt/wildfly/bin/jboss-cli.sh -c command="/system-property=nl.naturalis.nda.conf.dir:add(value=/etc/nba)"',
    unless      => '/opt/wildfly/bin/jboss-cli.sh -c command="ls system-property" | /bin/grep nl.naturalis.nda.conf.dir',
    require     => Service['wildfly'],
  }

  exec {'create nba logger':
    environment => 'JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64',
    cwd         => '/opt/wildfly/bin',
    command     => '/opt/wildfly/bin/jboss-cli.sh -c command="/subsystem=logging/logger=nl.naturalis.nda:add(level=DEBUG)"',
    unless      => '/opt/wildfly/bin/jboss-cli.sh -c command="ls subsystem=logging/logger" | /bin/grep nl.naturalis.nda',
    require     => Service['wildfly'],
  }


  class { 'elasticsearch':
    manage_repo  => true,
    version      => $es_version,
    repo_version => $es_repo_version,
    java_install => false,
    config       => {
      'cluster.name'                       => $nba_cluster_name,
      'index.number_of_shards'             => $es_shards,
      'index_number_of_replicas'           => $es_replicas,
      'discovery.zen.minimum_master_nodes' => $es_minimal_master_nodes
    },
    require      =>  Package['openjdk-8-jdk']
  }

  elasticsearch::instance { 'nba-es' :
    init_defaults => {
      'ES_HEAP_SIZE' => "${es_memory_gb}g"
    },
  }


}
