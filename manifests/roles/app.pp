#
#
#
class  nba::roles::app (

  # required variables
  $github_repository_key,
  $github_repository_version,
  $elasticsearch_cluster_name,
  $elasticsearch_ip_addresses,
  $wildfly_console_password,

  #optional variables
  $wildfly_debug    = false,
  $dcwa_eml_version = 'master',
  $deploy_export    = false,

){

  # stage { ['wildfly','build']:}
  #
  # Stage['wildfly'] -> Stage['build'] -> Stage['main']

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
        #username => 'wildfly',
        password => 'wildfly'
        }
      },
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

  # class { 'nba':
  #   nba_cluster_id      => $elasticsearch_cluster_name,
  #   console_listen_ip   => '127.0.0.1',
  #   admin_password      => $wildfly_console_password,
  #   extra_users_hash    => undef,
  #   nba_config_dir      => '/etc/nba',
  #   es_host_ip          => $elasticsearch_ip_addresses,
  #   es_transport_port   => '9300',
  #   index_name          => 'nda',
  #   wildfly_debug       => $wildfly_debug,
  #   wildfly_xmx         => '1024m',
  #   wildfly_xms         => '256m',
  #   wildlfy_maxpermsize => '512m',
  #   install_java        => false,
  #   #stage               => wildfly,
  # }

  class { 'nba::build':
    checkout      => $github_repository_version,
    repokey       => $github_repository_key,
    es_cluster_id => $elasticsearch_cluster_name,
    buildtype     => 'tag',
    build_ear     => true,
    build_export  => $deploy_export,
    deploy_ear    => true,
    main_es_ip    => $elasticsearch_ip_addresses,
    es_replicas   => 0,
    #stage         => build,
    require       => Class['wildfly']
  }

  # if ($deploy_export == true) {
  #   class { 'nba::export':
  #     version => $dcwa_eml_version,
  #     stage   => main,
  #   }
  # }
}
