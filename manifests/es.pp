# == Class: nba::es
#
class nba::es (
  $nba_cluster_name     = 'changeme',
  $es_version           = '1.3.4',
  $es_repo_version      = '1.3',
  $minimal_master_nodes = 2,
  $shards               = 9,
  $replicas             = 1,
  $es_memory_gb         = 8,
  $install_marvel       = false,
  $install_kopf         = false,
  $snapshot_directory   = '/data/snapshots',
  $mount_snapshot       = false,
  $snapshot_server      = '127.0.0.1',
  $install_java         = true,
  install_knapsack      = false,
){

  if $nba_cluster_name == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }

  $es_instance_name = 'nba-instance'

  class { 'elasticsearch':
    manage_repo  => true,
    version      => $es_version,
    repo_version => $es_repo_version,
    java_install => $install_java,
    config       => {
      'cluster.name'                       => $nba_cluster_name,
      'index.number_of_shards'             => $shards,
      'index_number_of_replicas'           => $replicas,
      'discovery.zen.minimum_master_nodes' => $minimal_master_nodes
    },
  }

  elasticsearch::instance { $es_instance_name :
    init_defaults => {
      'ES_HEAP_SIZE' => "${es_memory_gb}g"
    },
  }

  if $install_kopf {
    elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
      ensure     => present,
      module_dir => 'kopf',
      instances  => $es_instance_name,
    }
  }else{
    elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
      ensure     => absent,
      module_dir => 'kopf',
      instances  => $es_instance_name,
    }
  }
  if $install_marvel {
    elasticsearch::plugin{ 'elasticsearch/marvel/latest':
      ensure     => present,
      module_dir => 'marvel',
      instances  => $es_instance_name,
    }
  }else{
    elasticsearch::plugin{ 'elasticsearch/marvel/latest':
      ensure     => absent,
      module_dir => 'marvel',
      instances  => $es_instance_name,
    }
  }

  if $install_knapsack {
    elasticsearch::plugin{ 'elasticsearch/marvel/latest':
      ensure     => present,
      url        => 'http://xbib.org/repository/org/xbib/elasticsearch/plugin/elasticsearch-knapsack/1.5.1.0/elasticsearch-knapsack-1.5.1.0-plugin.zip'
      module_dir => 'knapsack',
      instances  => $es_instance_name,
      notify     => Service['elasticsearch'],
    }
  }else{
    elasticsearch::plugin{ 'elasticsearch/marvel/latest':
      ensure     => absent,
      url        => 'http://xbib.org/repository/org/xbib/elasticsearch/plugin/elasticsearch-knapsack/1.5.1.0/elasticsearch-knapsack-1.5.1.0-plugin.zip'
      module_dir => 'knapsack',
      instances  => $es_instance_name,
      notify     => Service['elasticsearch'],
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
