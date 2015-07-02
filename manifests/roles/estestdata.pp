#
#
#
class nba::roles::estestdata(
  # required variables
  $elasticsearch_cluster_name,
  $import_snapshot_url,
  # optional variables
  $deploy_with_snapshot = false,
  $deploy_snapshot_name = '',
  $elasticsearch_master_nodes = 2,
  $elasticsearch_memory = 8,
  $elasticsearch_shards = 9,
  $elasicsearch_replicas = 0,
){

  class { 'nba::es':
    nba_cluster_name     => $elasticsearch_cluster_name,
    es_version           => '1.3.4',
    es_repo_version      => '1.3',
    minimal_master_nodes => $elasticsearch_master_nodes,
    shards               => $elasticsearch_shards,
    replicas             => $elasicsearch_replicas,
    es_memory_gb         => $elasticsearch_memory,
    install_kopf         => true,
    install_java         => true,
  }

  sleep { 'wait for es to be up':
    bedtime       => 300,
    dozetime      => 5,
    failontimeout => true,
    wakeupfor     => 'curl -s -XGET localhost:9200/_cat/health | grep green',
  }

  es_repo { 'import':
    ensure   => present,
    type     => 'url',
    settings => {
      'url' => $import_snapshot_url,
    },
    ip       => '127.0.0.1',
    port     => '9200',
    require  => Sleep['wait for es to be up'],
  }

  if ($deploy_with_snapshot == true) {
    es_restore { 'deploy_restore':
      ensure        => present,
      snapshot_name => $deploy_snapshot_name,
      store_state   => true,
      repo          => 'import',
      indices       => ['nda'],
      ip            => '127.0.0.1',
      port          => '9200',
      require       => Es_repo['import']
    }
  }

}
