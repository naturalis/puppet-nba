#
#
#
class nba::all_in_one::all(
  $cluster_id    = 'demo',
  $es_replicas   = '0',
  $es_memory_gb  = '1',
  $nba_checkout  = 'v0.15',
  $build_nba     = true,
  $git_username,
  $git_password,
  $api_dns_name  = 'apitest.biodiversitydata.nl',
  $purl_dns_name = 'datatest.biodiversitydata.nl'
  ){

  if ($::cluster_ips) {
    if ($::cluster_ips == 'es_not_up') {
      notify {'elastic search not running asuming 1 node config':}
      $ips = ["${::ipaddress}:8080"]
    } else {
      $ips = suffix(split($::cluster_ips,','),':8080')
    }
  }else {
    $ips = ["${::ipaddress}:8080"]
  }

  if ($::cluster_nodes) {
    if ($::cluster_nodes == 'es_not_up') {
      notify {'elastic search not running asuming 1 node config':}
      $reps = '0'
    } else {
      $reps = $::cluster_nodes
    }
  }else {
    $reps ='0'
  }

  file {['/etc/facter','/etc/facter/facts.d/']:
    ensure => directory,
  } ->

  file {'/etc/facter/facts.d/es_nodes.py':
    ensure  => present,
    content => template('nba/facts/es_nodes.py'),
    mode    => '0775',
  }


  class {'nba::all_in_one::framework':
    nba_cluster_name        => $cluster_id,
    es_version              => '1.3.4',
    es_repo_version         => '1.3',
    es_shards               => '9',
    es_replicas             => $reps,
    es_minimal_master_nodes => '1',
    es_memory_gb            => $es_memory_gb,
  } ->

  class {'nba::all_in_one::lb':
    upstream => {
      'api_v0' => {
        'members' => $ips },
      'purl'   => {
        'members' => $ips }
      },
      vhost  => {
        "${api_dns_name}"  => {
          'www_root' => '/var/www/api.biodiversitydata.nl'},
        "${purl_dns_name}" => {
          'proxy' => 'http://purl/purl'}
      },
    require  => Service['elasticsearch-nba-es'],
  }

  class {'nba::all_in_one::api':
    checkout     => $nba_checkout,
    git_username => $git_username,
    git_password => $git_password,
    require      => Class['nba::all_in_one::lb'],
  }

  class {'nba::all_in_one::purl':
    require      => Class['nba::all_in_one::lb'],
  }

  class {'nba::all_in_one::kibana':
    require      => Class['nba::all_in_one::lb'],
  }

}
