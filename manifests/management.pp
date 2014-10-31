#
#
#
class nba::management(
  $allowed_ips      = ['127.0.0.1']
){

  package {'nfs-kernel-server':
    ensure => present
  } ->

  file {'/data/snapshots':
    ensure => directory,
    mode   => '0777',
  } ->

  file {'/etc/exports':
    ensure    => present,
    content   => template('nba/nfs/exports.erb'),
    notify    => Service['nfs-kernel-server'],
  }

  service {'nfs-kernel-server':
    ensure => running,
  }


}
