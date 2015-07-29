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
  $wildfly_sys_prop    = {
    'nl.naturalis.nda.conf.dir' => '/etc/nba'
  },
  $wildfly_logging     = 'default',
  $install_java        = true
){

  if $nba_cluster_id == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }

  if $extra_users_hash {
    create_resources('base::users', parseyaml($extra_users_hash))
  }



  file { ['/var/log/nba','/opt/nba_ear',$nba_config_dir]:
    ensure  => directory,
    mode    => '0770',
    owner   => 'wildfly',
    group   => 'wheel',
    require => User['wildfly']
  }

  file { "${nba_config_dir}/logback.xml":
    content => template('nba/nba/wildfly/logback.xml.erb'),
    mode    => '0644',
    require => File[$nba_config_dir],
  }


  file { '/etc/logrotate.d/nba':
    content => template('nba/nba/wildfly/logrotate.erb'),
    mode    => '0644',
  }

  if ($wildfly_logging == 'default') {
    class { 'wildfly':
      admin_password          => 'nda',
      admin_user              => 'nda',
      deployment_dir          => '/opt/wildfly_deployments',
      install_java            => $install_java,
      bind_address_management => $console_listen_ip,
      system_properties       => $wildfly_sys_prop,
      require                 => Package['curl'],
      debug_mode              => $wildfly_debug,
      xmx                     => $wildfly_xmx,
      xms                     => $wildfly_xms,
      maxpermsize             => $wildlfy_maxpermsize,
    }
  }else{
    class { 'wildfly':
      admin_password          => 'nda',
      admin_user              => 'nda',
      deployment_dir          => '/opt/wildfly_deployments',
      install_java            => $install_java,
      bind_address_management => $console_listen_ip,
      system_properties       => $wildfly_sys_prop,
      require                 => Package['curl'],
      debug_mode              => $wildfly_debug,
      xmx                     => $wildfly_xmx,
      xms                     => $wildfly_xms,
      maxpermsize             => $wildlfy_maxpermsize,
      logging_properties      => $wildfly_logging,
    }
  }




  file { '/opt/how_to_manual_deploy.txt':
    ensure  => present,
    owner   => 'wildfly',
    mode    => '0444',
    content => template('nba/howtodeploy.txt.erb'),
  }

}
