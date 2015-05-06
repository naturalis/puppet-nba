#
#
#
class nba::dcwa()
{
  vcsrepo { '/opt/test':
    ensure   => latest,
    provider => git,
    source   => 'git@github.com:atzedevries/thebsrepo.git',
    revision => 'master',
    require  => Package['git'],
    user     => 'atze.devries',
    notify   => Exec['new stuff exec']
  }

  exec { 'new stuff exec':
    command     => '/bin/ls /opt/test',
    refreshonly => true
  }
}
