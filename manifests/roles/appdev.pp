#
#
#
class  nba::roles::devapp (

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

  file {'/opt/wildfly_deployments':
    ensure => directory,
    mode   => '0777',
    before => Class['nba']
  }

  package {['git','ant','ivy','openjdk-7-jdk']:
    ensure => installed,
    before => Class['nba']
  }

  exec {'add ivy env':
      cmd    => '/bin/echo \'IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/\' >> /etc/environment',
      unless => '/bin/grep environment -e IVY_HOME',
  }

  class { 'nba':
    nba_cluster_id      => $elasticsearch_cluster_name,
    console_listen_ip   => '127.0.0.1',
    admin_password      => $wildfly_console_password,
    extra_users_hash    => undef,
    nba_config_dir      => '/etc/nba',
    es_host_ip          => $elasticsearch_ip_addresses,
    es_transport_port   => '9300',
    index_name          => 'nda',
    wildfly_debug       => true,
    wildfly_xmx         => '1024m',
    wildfly_xms         => '256m',
    wildlfy_maxpermsize => '512m',
    install_java        => false,
    #stage               => wildfly,
  }


}
