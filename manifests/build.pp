#
#
#
class nba::build(
  $checkout,
)
{
  package {['git','ant','ivy','openjdk-7-jdk']:
    ensure => installed
  }

  file { '/etc/profile.d/ivy.sh':
    content => 'export IVY_HOME="/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/"'
  }

  vcsrepo { '/opt/nba-git':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/naturalis/naturalis_data_api',
    revision => $checkout,
    require  => Package['git'],
    notify   => Exec['build nba'],
    user     => 'root'
  }

  exec { 'build nba':
    cwd         => '/opt/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
    command     => '/usr/bin/ant rebuild',
    refreshonly => true
  }



}
