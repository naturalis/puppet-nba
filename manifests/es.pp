# == Class: nba::es
#
class nba::es (
  $nba_cluster_name   = 'changeme',
  $es_version         = '1.3.4',
  $es_repo_version    = '1.3'
  $shards             = 9,
  $replicas           = 1,
  $es_memory_gb       = 8,
  $install_marvel     = false,
  $install_kopf       = false,
  $snapshot_directory = '/data/snapshots',
  $mount_snapshot     = false,
  $snapshot_server    = '127.0.0.1',
){

  if $nba_cluster_name == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }

  $es_instance_name = 'nba-instance'

  class { 'elasticsearch':
    manage_repo  => true,
    version      => $es_version,
    repo_version => $es_repo_version,
    java_install => true,
    config       => {
      'cluster.name'             => $nba_cluster_name,
      'index.number_of_shards'   => $shards,
      'index_number_of_replicas' => $replicas
    },
  }

  elasticsearch::instance { $es_instance_name :
    init_defaults => {
      'ES_HEAP_SIZE' => "${es_memory_gb}g"
    },
  }

  if $install_kopf {
    elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
      module_dir => 'kopf',
      instances  => $es_instance_name,
    }
  }
  if $install_marvel {
    elasticsearch::plugin{ 'elasticsearch/marvel/latest':
      module_dir => 'marvel',
      instances  => $es_instance_name,
    }
  }


  # elasticsearch::instance { 'es-01':
  #   config => { },        # Configuration hash
  #   init_defaults => { }, # Init defaults hash
  # }


  if $mount_snapshot {

    package {'nfs-common':}

    file {['/data',$snapshot_directory]:
      ensure => directory,
      mode   => '0777',
    } ->

    exec {"mount snapshot dir to ${snapshot_directory}":
      command => "/bin/mount ${snapshot_server}:/data/snapshots ${snapshot_directory}",
      unless  => "/bin/mount | grep ${snapshot_server} | grep ${snapshot_directory}",
      require => Package['nfs-common']
    }
  }

}
