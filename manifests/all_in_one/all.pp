#
#
#
class nba::all_in_one::all(
  $cluster_id    = 'demo',
  $es_memory_gb  = '1',
  $nba_checkout  = 'v0.15',
  $build_nba     = true,
  $git_username,
  $git_password,
  $api_dns_name  = 'apitest.biodiversitydata.nl',
  $purl_dns_name = 'datatest.biodiversitydata.nl',
  $always_build_latest = false,
  $nbav2               = false,

  ){

  if ($::cluster_ips) {
    if ($::cluster_ips == 'es_not_up') {
      notify {'elastic search not running asuming 1 node config, using one ip only':}
      $ips = ["${::ipaddress}:8080"]
    } else {
      $ips = suffix(split($::cluster_ips,','),':8080')
    }
  }else {
    $ips = ["${::ipaddress}:8080"]
  }

  if ($::suggested_reps) {
    if ($::suggested_reps == 'es_not_up') {
      notify {'elastic search not running asuming 1 node config with 0 replicas':}
      $reps = '0'
    } else {
      $reps = $::suggested_reps
    }
  }else {
    $reps ='0'
  }

  if ($::suggested_master_nodes) {
    if ($::suggested_master_nodes == 'es_not_up') {
      notify {'elastic search not running asuming 1 node config':}
      $minmaster = '1'
    } else {
      $minmaster = $::suggested_master_nodes
    }
  }else {
    $minmaster ='1'
  }

  if ($always_build_latest == false) {
    $what_to_build = 'present'
  } else {
    $what_to_build = 'latest'
  }

  file {['/etc/facter','/etc/facter/facts.d/']:
    ensure => directory,
  } ->

  file {'/etc/facter/facts.d/es_nodes.py':
    ensure  => present,
    content => template('nba/facts/es_nodes.py'),
    mode    => '0775',
  }
  if ( $nbav2 == true ) {

    class {'nba::all_in_one::frameworkv2':
      nba_cluster_name        => $cluster_id,
      es_replicas             => $reps,
      es_minimal_master_nodes => $minmaster,
      es_memory_gb            => $es_memory_gb,
      before                  => Class['nba::all_in_one::lb']
    }

    class {'nba::all_in_one::apiv2':
      checkout      => $nba_checkout,
      git_username  => $git_username,
      git_password  => $git_password,
      what_to_build => $what_to_build,
      build         => $build_nba,
      require       => Class['nba::all_in_one::lb'],
    }

  } else {

    class {'nba::all_in_one::framework':
      nba_cluster_name        => $cluster_id,
      es_version              => '1.3.4',
      es_repo_version         => '1.3',
      es_shards               => '9',
      es_replicas             => $reps,
      es_minimal_master_nodes => $minmaster,
      es_memory_gb            => $es_memory_gb,
      before                  => Class['nba::all_in_one::lb']
    }

    class {'nba::all_in_one::api':
      checkout      => $nba_checkout,
      git_username  => $git_username,
      git_password  => $git_password,
      what_to_build => $what_to_build,
      build         => $build_nba,
      require       => Class['nba::all_in_one::lb'],
    }
  }

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



  if ( $nbav2 == false ) {
    class {'nba::all_in_one::purl':
      require      => Class['nba::all_in_one::lb'],
    }
  }

  class {'nba::all_in_one::kibana':
    require      => Class['nba::all_in_one::lb'],
  }

  cron { 'apply puppet at boot':
    command => '/usr/bin/puppet apply /etc/puppet/manifests/nba.pp',
    user    => root,
    special => reboot,
  }

  exec {'set es number of replicas':
    command => "/bin/sleep 30 ; /usr/bin/curl -XPUT 127.0.0.1:9200/_settings -d '{ \"index\":{\"number_of_replicas\": ${reps} } }'",
    require =>  Service['elasticsearch-nba-es'],
  }
}
