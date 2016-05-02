#
#
#
class nba::all_in_one::all(
  $cluster_id = 'demo',
  $es_replicas   = '0',
  $es_memory_gb = '1',
  ){

  if ($::cluster_ips) {
    if ($::cluster_ips == 'es_not_up') {
      notify {'elastic search not running asuming 1 node config':}
      $ips = $::ipaddress
    } else {
      $ips = split($::cluster_ips,',')
    }
  }else {
    $ips = $::ipaddress
  }




  class {'nba::all_in_one::framework':
    nba_cluster_name        => $cluster_id,
    es_version              => '1.3.4',
    es_repo_version         => '1.3',
    es_shards               => '9',
    es_replicas             => $es_replicas
    es_minimal_master_nodes => '1',
    es_memory_gb            => $es_memory_gb
  } ->

  class {'nba::all_in_one::lb':
    upstream => {
      'api_v0' => {
        'members' => $ips
        },
      'purl'   => {
        'members' => $ips
        }
      },
  }


}
