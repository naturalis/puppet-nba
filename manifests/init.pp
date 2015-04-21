# == Class: nba
#
# Full description of class nba here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { nba:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class nba (
  $nba_cluster_id      = 'changeme',
  $console_listen_ip   = '127.0.0.1',
  $admin_password      = 'nba',
  $application_name    = 'nba.ear',
  $deploy_file         = 'nda-0.9.000.ear',
  $nba_version         = '0.9.000',
  $deploy_source_dir   = 'puppet:///modules/nba/',
  $extra_users_hash    = undef,
  $nba_config_dir      = '/etc/nba',
  $es_host_ip          = '127.0.0.1',
  $es_transport_port   = '9300',
  $index_name          = 'nda',
  $wildfly_debug       = false,
  $wildfly_xmx         = '1024m',
  $wildfly_xms         = '256m',
  $wildlfy_maxpermsize = '512m',
){

  if $nba_cluster_id == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }

  if $extra_users_hash {
    create_resources('base::users', parseyaml($extra_users_hash))
  }

  #build of new nba with build scripts
  # packages: git,ant,ivy,openjdk-7-jdk
  # env: $IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0
  # run to build
  # all: ant rebuild
  # ear: ant clean ear


  file { ['/var/log/nba','/opt/nba_ear',$nba_config_dir,'/opt/wildfly_deployments']:
    ensure  => directory,
    mode    => '0755',
    owner   => 'wildfly',
    group   => 'wildfly',
    require => User['wildfly']
  }

  file { "${nba_config_dir}/logback.xml":
    content => template('nba/nba/wildfly/logback.xml.erb'),
    mode    => '0644',
    require => File[$nba_config_dir],
  }

  file { "${nba_config_dir}/nda.properties":
    content => template('nba/nba/wildfly/nda.properties.erb'),
    mode    => '0644',
    require => File[$nba_config_dir],
  }

  file { '/etc/logrotate.d/nba':
    content => template('nba/nba/wildfly/logrotate.erb'),
    mode    => '0644',
  }

  class { 'wildfly':
    admin_password          => 'nda',
    admin_user              => 'nda',
    deployment_dir          => '/opt/wildfly_deployments',
    install_java            => true,
    bind_address_management => $console_listen_ip,
    system_properties       => { 'nl.naturalis.nda.conf.dir' => $nba_config_dir },
    require                 => Package['curl'],
    debug_mode              => $wildfly_debug,
    xmx                     => $wildfly_xmx,
    xms                     => $wildfly_xms,
    maxpermsize             => $wildlfy_maxpermsize,
  }

  

  # file { "/opt/nba_ear/${deploy_file}":
  #   ensure  => present,
  #   source  => "${deploy_source_dir}${deploy_file}",
  #   owner   => 'wildfly',
  #   group   => 'wildfly',
  #   require => File['/opt/nba_ear'],
  #   notify  => Exec["deploy or update war with ${deploy_file}"],
  # }

  # exec { "deploy or update war with ${deploy_file}":
  #   command     => "/bin/cp -f /opt/nba_ear/${deploy_file} /opt/wildfly_deployments/${application_name}",
  #   require     => [Class['wildfly'],File['/opt/wildfly_deployments']],
  #   refreshonly => true,
  # }

  # Moved to nginx loadbalancer/rp
  #
  # class { 'nginx': }
  #
  # nginx::resource::upstream { 'nba_v1_wildfly_app':
  #   members => ['localhost:8080',],
  # }
  #
  # nginx::resource::vhost { 'api.biodiversity.nl':
  #   proxy => 'http://nba_v1_wildfly_app/',
  #   # proxy => 'http://nba_v1_wildfly_app/nl.naturalis.nda.service.rest/',
  # }

  file { '/opt/how_to_manual_deploy.txt':
    ensure  => present,
    owner   => 'wildfly',
    mode    => '0444',
    content => template('nba/howtodeploy.txt.erb'),
  }

}
