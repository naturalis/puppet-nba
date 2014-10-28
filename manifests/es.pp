# == Class: nba::es
#
class nba::es (
  $nba_cluster_name   = 'changeme',
  $es_version         = '1.3.2',
  $shards             = 1,
  $replicas           = 0,
  $es_memory_gb       = 8,
  $es_data_dir        = '/data/elasticsearch',
  $install_marvel     = false,
  $snapshot_directory = '/data/snapshots'
){

  if $nba_cluster_name == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }

  class{ 'elasticsearch':
    package_url               => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${es_version}.deb",
    config                    => {
        'node'                  => {
          'name'                => $::hostname
        },
        'index'                 => {
          'number_of_shards'    => $shards,
          'number_of_replicas'  => $replicas
        },
        'cluster'               => {
          'name'                => $nba_cluster_name
        }
      },
    java_install              => true,
    init_defaults             => {
        'ES_HEAP_SIZE'          => "${$es_memory_gb}g",
        'DATA_DIR'              => $es_data_dir
    },
  }

  if $install_marvel {
    exec { 'install marvel' :
      command => '/usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/latest',
      unless  => '/usr/bin/test -d /usr/share/elasticsearch/plugins/marvel',
    }
  }

  file {['/data',$snapshot_directory]:
    ensure => directory,
    mode   => '0777',
  }

}
