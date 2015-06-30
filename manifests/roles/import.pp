#
#
#
class nba::roles::import(
  # required variables
  $github_repository_key,
  $github_repository_version,
  $elasticsearch_cluster_name,

  #optional variables
  $dcwa_eml_version = 'master',
  $deploy_export    = false,
  $elasticsearch_memory = 8,

){

  stage { ['import','build']:}

  Stage['build'] -> Stage['main'] -> Stage['import']

  package {['git','ant','ivy','openjdk-7-jdk']:
    ensure => installed,
    before => [Class['nba::build'],Class['nba::es']]
  }

  class { 'nba::build':
    checkout      => $github_repository_version,
    repokey       => $github_repository_key,
    es_cluster_id => $elasticsearch_cluster_name,
    buildtype     => 'tag',
    build_ear     => false,
    build_export  => $deploy_export,
    build_import  => false,
    main_es_ip    => '127.0.0.1',
    es_replicas   => 0,
    stage         => build,
  }

  class { 'nba::es':
    nba_cluster_name     => $elasticsearch_cluster_name,
    es_version           => '1.3.4',
    es_repo_version      => '1.3',
    minimal_master_nodes => 1,
    shards               => 9,
    replicas             => 0,
    es_memory_gb         => $elasticsearch_memory,
    install_kopf         => true,
    install_java         => false,
  }

  exec {'add ivy env':
      command => '/bin/echo \'IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/\' >> /etc/environment',
      unless  => '/bin/grep environment -e IVY_HOME',
  }

  if ($deploy_export == true) {
    class { 'nba::export':
      version => $dcwa_eml_version,
      stage   => main,
    }
  }

  class { 'nba::import':
    stage => 'import',
  }
}
