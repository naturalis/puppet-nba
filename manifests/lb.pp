#
#
#
class nba::lb (
  $nba_cluster_id = 'changme',
  $port           = '8080',
  $ip             = undef,
  ){

  if $nba_cluster_id == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }

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
