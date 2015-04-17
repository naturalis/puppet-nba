#
#
#
class nba::dcwa()
{
  vcsrepo { '/opt/nba-git':
    ensure   => latest,
    provider => git,
    source   => 'git@github.com:atzedevries/thebsrepo.git',
    revision => 'master',
    require  => Package['git'],
    user     => 'root',
    notify   => Notify['new stuff']
  }

  notify {'new stuff':
    message => 'neeeWWWWWWW stuff!'
  }
}
