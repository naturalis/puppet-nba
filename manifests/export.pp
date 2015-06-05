#
#
#
class nba::export(
  $version = 'latest',
)
{

  if !defined(File['/data']) {
    file { '/data': ensure => directory }
  }

  file { ['/data/dcwa-zip','/data/dcwa-conf','/data/export-log'] :
    ensure => directory,
  }

  if (version == 'latest' ) {
    vcsrepo { '/data/dcwa-conf/dcwa':
      ensure   => latest,
      provider => git,
      source   => 'git@github.com:naturalis/nba-eml.git',
      revision => 'master',
      require  => [Package['git'],File['/data/dcwa-conf']],
      notify   => Exec['run export'],
    }
  } else {
    vcsrepo { '/data/dcwa-conf/dcwa':
      ensure   => present,
      provider => git,
      source   => 'git@github.com:naturalis/nba-eml.git',
      revision => $version,
      require  => [Package['git'],File['/data/dcwa-conf']],
      notify   => Exec['run export'],
    }
  }

  exec { 'run export':
    command     => '/bin/sh /data/nba-export/sh/export-dwca.sh',
    require     => File['/data/dcwa-zip'],
    refreshonly => true,
  }
}
