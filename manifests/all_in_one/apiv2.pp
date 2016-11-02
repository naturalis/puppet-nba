#
#
#
class nba::all_in_one::apiv2(
  $checkout,
  $git_username,
  $git_password,
  $what_to_build = 'latest',
  $build = true
){

  ## Defaults
  Exec {
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    logoutput   => false,
    cwd         => '/source/nba-git/nl.naturalis.nba.build',
    subscribe   => Vcsrepo['/source/nba-git'],
    refreshonly => true,
    require     => [
      File['/source/nba-git/nl.naturalis.nba.build/build.v2.properties'],
      Es_Instance_Conn_Validator['nba-es'],
    ],
  }

  es_instance_conn_validator { 'nba-es' :
    server => 'localhost',
    port   => '9200',
  }


  vcsrepo { '/source/nba-git':
    ensure   => $what_to_build,
    provider => git,
    source   => "https://${git_username}:${git_password}@github.com/naturalis/naturalis_data_api",
    revision => $checkout,
    require  => Package['git'],
  } ->

  file {'/data':
    ensure => directory
  } ->

  file {'/etc/nba':
    ensure => directory
  } ->



  file { '/source/nba-git/nl.naturalis.nba.build/build.v2.properties':
    ensure  => present,
    content => template('nba/build/build.v2.properties_all.erb'),
  }

  if ( $build == true ) {
    exec {'/usr/bin/ant install-service': } ->
    exec {'/usr/bin/ant install-etl-module': }
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


###










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
