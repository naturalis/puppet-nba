#
#
#
class nba::management(
  $nba_cluster_name = 'changeme',
  $allowed_ips      = ['127.0.0.1']
){

  if $nba_cluster_name == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }
  # if $nfs_mount_CIDR == 'changeme' { fail('Change the variable nfs_mount_CIDR to a propper one (for example 172.16.10.0/24)') }

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
    subscribe => Service['nfs-kernel-server'],
  }

  service {'nfs-kernel-server':
    ensure => running,
  }

  # @@exec {'mount snapshot dir':
  #   cmd    => "/bin/mount -t nfs -o proto=tcp,port=2049 ${network_eth0}:/data/snapshots /data/snapshots",
  #   unless => '/bin/mount | /bin/grep "/data/snapshots"',
  #   tags   => "nba_nfs_mount_${nba_cluster_name}",
  # }



}
