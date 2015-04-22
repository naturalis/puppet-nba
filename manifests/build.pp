#
#
#
class nba::build(
  $checkout,
  $repokey,
  $buildtype    = 'tag',
  $build_ear    = true,
  $build_import = false,
  $build_export = false,
  $deploy_ear   = false,
)
{

  case $buildtype {
    'tag':    {$deploy_cmd = '/usr/bin/ant clean ear' }
    'commit': {$deploy_cmd = '/usr/bin/ant clean nightly ear'}
    default:  { fail('variable: build type need to be "tag" or "commit"')}
  }

  #fail ('Unable to deploy ear without build of ear') if $build_ear == false and $deploy_ear == true

  package {['git','ant','ivy']:
    ensure => installed
  }

  if !defined(Package['openjdk-7-jdk']) {
    package { 'openjdk-7-jdk': ensure => installed }
  }

  file { '/etc/profile.d/ivy.sh':
    content => 'export IVY_HOME="/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/"'
  }

  file { '/root/.ssh':
    ensure    => directory,
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
    unless   => 'test -f /root/.ssh/known_hosts'
  }->
# give known_hosts file the correct permissions
  file{ '/root/.ssh/known_hosts':
    mode      => '0600',
  }->

  vcsrepo { '/opt/nba-git':
    ensure   => present,
    provider => git,
    source   => 'git@github.com:naturalis/naturalis_data_api.git',
    revision => $checkout,
    require  => Package['git'],
    user     => 'root',
  }

  file { '/opt/nba-git/nl.naturalis.nda.build/build.properties':
    ensure  => present,
    content => template('nba/nba/build/build.properties.erb'),
    require => Vcsrepo['/opt/nba-git'],
    notify  => Exec['build sh-config'],
  }

  if $build_ear {
    exec { 'build ear':
      cwd         => '/opt/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => $deploy_cmd,
      refreshonly => true,
      subscribe   => [
        Vcsrepo['/opt/nba-git'],
        File['/opt/nba-git/nl.naturalis.nda.build/build.properties']
      ]
    }
  }

  if $deploy_ear {
    exec { 'deploy nba':
      cwd         => '/opt/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant deploy',
      refreshonly => true,
      subscribe   => Exec['build ear'],
    }
  }


  if $build_import {
    exec { 'build import':
      cwd         => '/opt/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant clean load',
      refreshonly => true,
      subscribe   => [
        Vcsrepo['/opt/nba-git'],
        File['/opt/nba-git/nl.naturalis.nda.build/build.properties']
      ],
      notify      => Exec['build sh'],
    }
  }
  if $build_export {
    exec { 'build export':
      cwd         => '/opt/nba-git/nl.naturalis.nda.build',
      environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
      command     => '/usr/bin/ant clean export',
      refreshonly => true,
      subscribe   => [
        Vcsrepo['/opt/nba-git'],
        File['/opt/nba-git/nl.naturalis.nda.build/build.properties']
      ],
      notify      => Exec['build sh']
    }
  }

  exec { 'build sh':
    cwd         => '/opt/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
    command     => '/usr/bin/ant clean sh',
    refreshonly => true,
  }

  exec { 'build sh-config':
    cwd         => '/opt/nba-git/nl.naturalis.nda.build',
    environment => ['IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/'],
    command     => '/usr/bin/ant clean sh-config',
    refreshonly => true,
  }

}