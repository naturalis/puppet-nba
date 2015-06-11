#
#
#
class nba::build(
  $checkout,
  $repokey,
  $es_cluster_id,
  $buildtype    = 'tag',
  $build_ear    = true,
  $build_import = false,
  $build_export = false,
  $deploy_ear   = false,
  $main_es_ip   = '127.0.0.1',
  $es_replicas  = 1,
  $ivy_home     = '/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'
)
{

  case $buildtype {
    'tag':    {$deploy_cmd = "/usr/bin/sudo /bin/bash -c \"export IVY_HOME=${ivy_home} ; cd /source/nba-git/nl.naturalis.nda.build ; /usr/bin/ant clean build-ear-file\"" }
    'commit': {$deploy_cmd = "/usr/bin/sudo /bin/bash -c \"export IVY_HOME=${ivy_home} ; cd /source/nba-git/nl.naturalis.nda.build ; /usr/bin/ant clean nighty build-ear-file\""}
    default:  { fail('variable: build type need to be "tag" or "commit"')}
  }



  # if !defined(File['/data']) {
  #   file { '/data':
  #     ensure => directory,
  #   }
  # }
  file {'/opt/wildfly_deployments':
    ensure => directory,
    mode   => '0777',
  }

  file {'/data':
    ensure => directory,
    mode   => '0775',
  }
  #fail ('Unable to deploy ear without build of ear') if $build_ear == false and $deploy_ear == true

  package {['git','ant','ivy','openjdk-7-jdk']:
    ensure => installed,
  }

  # if !defined(Package['openjdk-7-jdk']) {
  #   package { 'openjdk-7-jdk':
  #     ensure => installed,
  #   }
  # }

#   file { '/etc/environment':
#     content => 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
# IVY_HOME="/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/"',
#   }

  file { '/root/.ssh':
    ensure => directory,
  }->
# Create /root/.ssh/repokeyname file
  file { '/root/.ssh/nbagit':
    ensure  => present,
    content => $repokey,
    mode    => '0600',
  }->
# Create sshconfig file
  file { '/root/.ssh/config':
    ensure  => present,
    content =>  "Host github.com\n\tIdentityFile ~/.ssh/nbagit",
    mode    => '0600',
  }->
# copy known_hosts.sh file from puppet module
  file{ '/usr/local/sbin/known_hosts.sh' :
    ensure => present,
    mode   => '0700',
    source => 'puppet:///modules/nba/known_hosts.sh',
  }->
# run known_hosts.sh for future acceptance of github key
  exec{ 'add_known_hosts' :
    command  => '/usr/local/sbin/known_hosts.sh',
    path     => '/sbin:/usr/bin:/usr/local/bin/:/bin/',
    provider => shell,
    user     => 'root',
    unless   => 'test -f /root/.ssh/known_hosts',
  }->
# give known_hosts file the correct permissions
  file{ '/root/.ssh/known_hosts':
    mode  => '0600',
  }->

  vcsrepo { '/source/nba-git':
    ensure   => present,
    provider => git,
    source   => 'git@github.com:naturalis/naturalis_data_api.git',
    revision => $checkout,
    require  => Package['git'],
    user     => 'root',
  }

  file { '/source/nba-git/nl.naturalis.nda.build/build.properties':
    ensure  => present,
    content => template('nba/build/build.properties.erb'),
    require => Vcsrepo['/source/nba-git'],
    #notify  => Exec['build sh-config'],
  }

  if $build_ear {
    exec { 'build ear':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      logoutput   => true,
      #command     => $deploy_cmd,
      command     => '/usr/bin/ant clean build-ear-file',
      refreshonly => true,
      subscribe   => [
        Vcsrepo['/source/nba-git'],
        File['/source/nba-git/nl.naturalis.nda.build/build.properties']
      ],
    }
  }

  if $deploy_ear {

    exec { 'deploy nba':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/','PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'],
      #command     => "/usr/bin/sudo /bin/bash -c \"export IVY_HOME=${ivy_home} ;  cd /source/nba-git/nl.naturalis.nda.build ; /usr/bin/ant deploy-ear-file\"" ,
      command     => '/usr/bin/ant deploy-ear-file',
      refreshonly => true,
      require     => File['/opt/wildfly_deployments'],
      subscribe   => Exec['build ear'],
    }
  }


  if $build_import {
    exec { 'build import':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant clean install-import-module',
      refreshonly => true,
      subscribe   => [
        Vcsrepo['/source/nba-git'],
        File['/source/nba-git/nl.naturalis.nda.build/build.properties']
      ],
      #notify      => Exec['build sh'],
    }

    exec { 'patch-import':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant install-import-cli',
      refreshonly => true,
      require     => Exec['build import'],
      subscribe   => File['/source/nba-git/nl.naturalis.nda.build/build.properties'],
    }

  }
  if $build_export {
    exec { 'build export':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant clean install-export-module',
      refreshonly => true,
      subscribe   => [
        Vcsrepo['/source/nba-git'],
        File['/source/nba-git/nl.naturalis.nda.build/build.properties']
      ],
    }
    exec { 'patch-export':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant install-export-cli',
      refreshonly => true,
      require     => Exec['build export'],
      subscribe   => File['/source/nba-git/nl.naturalis.nda.build/build.properties'],
    }
  }

}
