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
  $es_replicas  = 1
)
{

  case $buildtype {
    'tag':    {$deploy_cmd = '/usr/bin/ant clean build-ear-file' }
    'commit': {$deploy_cmd = '/usr/bin/ant clean nightly build-ear-file'}
    default:  { fail('variable: build type need to be "tag" or "commit"')}
  }

  stage {'build':
    before => Stage['main']
  }

  if !defined(File['/data']) {
    file { '/data':
      ensure => directory,
    }
  }

  #fail ('Unable to deploy ear without build of ear') if $build_ear == false and $deploy_ear == true

  package {['git','ant','ivy']:
    ensure => installed,
    stage  => build,
  }

  if !defined(Package['openjdk-7-jdk']) {
    package { 'openjdk-7-jdk':
      ensure => installed,
      stage  => build,
    }
  }

  file { '/etc/environment':
    content => 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
IVY_HOME="/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/"',
  }

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
    stage    => build,
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
    stage    => build,
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
      command     => $deploy_cmd,
      refreshonly => true,
      subscribe   => [
        Vcsrepo['/source/nba-git'],
        File['/source/nba-git/nl.naturalis.nda.build/build.properties']
      ],
      stage       => build,
    }
  }

  if $deploy_ear {
    exec { 'deploy nba':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant deploy-ear-file',
      refreshonly => true,
      require     => File['/opt/wildfly_deployments'],
      subscribe   => Exec['build ear'],
      stage       => build,
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
      stage       => build,
      #notify      => Exec['build sh'],
    }

    exec { 'patch-import':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant install-import-cli',
      refreshonly => true,
      require     => Exec['build import'],
      subscribe   => File['/source/nba-git/nl.naturalis.nda.build/build.properties'],
      stage       => build,
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
      stage       => build,
    }
    exec { 'patch-export':
      cwd         => '/source/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant install-export-cli',
      refreshonly => true,
      require     => Exec['build export'],
      subscribe   => File['/source/nba-git/nl.naturalis.nda.build/build.properties'],
      notify      => Exec['run export'],
      stage       => build,
    }
  }

}
