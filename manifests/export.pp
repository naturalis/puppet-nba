#
#
#
class nba::export(
  $version = 'latest',
)
{

  file { ['/data/dwca-zip','/data/dwca-conf','/data/export-log'] :
    ensure => directory,
  }

  if ($version == 'latest' ) {
    vcsrepo { '/data/dwca-conf/dwca':
      ensure   => latest,
      provider => git,
      source   => 'git@github.com:naturalis/nba-eml.git',
      revision => 'master',
      require  => [Package['git'],File['/data/dwca-conf']],
      notify   => Exec['run export'],
    }
  } else {
    vcsrepo { '/data/dwca-conf/dwca':
      ensure   => present,
      provider => git,
      source   => 'git@github.com:naturalis/nba-eml.git',
      revision => $version,
      require  => [Package['git'],File['/data/dwca-conf']],
      notify   => Exec['run export'],
    }
  }

  exec { 'run export':
    cwd         => '/data/nba-export/sh/'
    command     => '/bin/sh /data/nba-export/sh/export-dwca.sh',
    require     => File['/data/dwca-zip'],
    refreshonly => true,
  }
}
