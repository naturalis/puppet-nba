#
#
#
class nba::all_in_one::api(
  $checkout,
  $git_username,
  $git_password,
  ){

  ## Defaults
  Exec {
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    environment => 'IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/',
    logoutput   => false,
    cwd         => '/source/nba-git/nl.naturalis.nda.build',
  }


  vcsrepo { '/source/nba-git':
    ensure   => present,
    provider => git,
    source   => "https://${git_username}:${git_password}@github.com/naturalis/naturalis_data_api",
    revision => $checkout,
    require  => Package['git'],
    #user     => 'root',
  } ->

  file {'/data':
    ensure => directory
  } ->

  file { '/source/nba-git/nl.naturalis.nda.build/build.properties':
    ensure  => present,
    content => template('nba/build/build.properties_all.erb'),
    #require => Vcsrepo['/source/nba-git'],
    #notify  => Exec['build sh-config'],
  } ->

  exec {'/usr/bin/ant clean build-ear-file': } ->
  exec {'/usr/bin/ant deploy-ear-file': } ->
  exec {'/usr/bin/ant clean install-import-module': } ->
  exec {'/usr/bin/ant clean install-export-module': } ->
  exec {'/data/nda-import/sh/bootstrap-nba.sh':
    cwd    => '/data/nda-import/sh',
    nofity => Service['wildfly']
  }


  # exec { 'build ear':
  #   cwd         => '/source/nba-git/nl.naturalis.nda.build',
  #   environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
  #   logoutput   => true,
  #   #command     => $deploy_cmd,
  #   command     => '/usr/bin/ant clean build-ear-file',
  #   # refreshonly => true,
  #   # subscribe   => [
  #   #   Vcsrepo['/source/nba-git'],
  #   #   File['/source/nba-git/nl.naturalis.nda.build/build.properties']
  #   # ],
  # } ->
  #
  #
  #
  # exec { 'deploy nba':
  #   cwd         => '/source/nba-git/nl.naturalis.nda.build',
  #   environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/','PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'],
  #   #command     => "/usr/bin/sudo /bin/bash -c \"export IVY_HOME=${ivy_home} ;  cd /source/nba-git/nl.naturalis.nda.build ; /usr/bin/ant deploy-ear-file\"" ,
  #   command     => '/usr/bin/ant deploy-ear-file',
  #   # refreshonly => true,
  #   # require     => Class['::Wildfly'],
  #   # subscribe   => Exec['build ear'],
  # } ->
  #
  # exec { 'build import':
  #   cwd         => '/source/nba-git/nl.naturalis.nda.build',
  #   environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
  #   command     => '/usr/bin/ant clean install-import-module',
  #   # refreshonly => true,
  #   # subscribe   => [
  #   #   Vcsrepo['/source/nba-git'],
  #   #   File['/source/nba-git/nl.naturalis.nda.build/build.properties']
  #   # ],
  #   #notify      => Exec['build sh'],
  # } ->
  #
  # exec { 'patch-import':
  #   cwd         => '/source/nba-git/nl.naturalis.nda.build',
  #   environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
  #   command     => '/usr/bin/ant install-import-cli',
  #   # refreshonly => true,
  #   # require     => Exec['build import'],
  #   # subscribe   => File['/source/nba-git/nl.naturalis.nda.build/build.properties'],
  # } ->
  #
  # exec { 'build export':
  #   cwd         => '/source/nba-git/nl.naturalis.nda.build',
  #   environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
  #   command     => '/usr/bin/ant clean install-export-module',
  #   # refreshonly => true,
  #   # subscribe   => [
  #   #   Vcsrepo['/source/nba-git'],
  #   #   File['/source/nba-git/nl.naturalis.nda.build/build.properties']
  #   # ],
  # } ->
  # exec { 'patch-export':
  #   cwd         => '/source/nba-git/nl.naturalis.nda.build',
  #   environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
  #   command     => '/usr/bin/ant install-export-cli',
  #   # refreshonly => true,
  #   # require     => Exec['build export'],
  #   # subscribe   => File['/source/nba-git/nl.naturalis.nda.build/build.properties'],
  # }

}
