#
#
#
class nba::lb (
  $nba_cluster_id,
  $port = '8080',
  $ip = undef,
  ){

  if ($ip) {
    $ip_real = $ip
  }else{
    $ip_real = $::ipaddress
  }

  class { 'haproxy': }

  haproxy::listen { $nba_cluster_id :
    ipaddress => $ip_real,
    ports     => $port,
  }

  Haproxy::Balancermember <<| listening_service == $nba_cluster_id |>> {
    require => Haproxy::Listen[$nba_cluster_id],
  }




}
