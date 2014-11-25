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
  $nba_cluster_id     = 'changeme',
  $console_listen_ip  = '127.0.0.1',
  $admin_password     = 'nba',
  $application_name   = 'nba.ear',
  $deploy_file        = 'nda-0.9.000.ear',
  $deploy_source_dir  = 'puppet:///modules/nba/',
  $extra_users_hash   = undef,
  $nba_config_dir     = '/etc/nba',
  $es_host_ip         = '127.0.0.1',
  $es_transport_port  = '9300'
){

  if $nba_cluster_id == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }

  if $extra_users_hash {
    create_resources('base::users', parseyaml($extra_users_hash))
  }


  file { ['/var/log/nb
  a','/opt/nba_ear',$nba_config_dir,'/opt/wildfly_deployments']:
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

  class { 'wildfly':
    admin_password          => 'nda',
    admin_user              => 'nda',
    deployment_dir          => '/opt/wildfly_deployments',
    install_java            => true,
    bind_address_management => $console_listen_ip,
    system_properties       => { 'nl.naturalis.nda.conf.dir' => $nba_config_dir },
    require                 => Package['curl']
  }

  file { "/opt/nba_ear/${deploy_file}":
    ensure  => present,
    source  => "${deploy_source_dir}${deploy_file}",
    owner   => 'wildfly',
    group   => 'wildfly',
    require => File['/opt/nba_ear'],
    notify  => Exec["deploy or update war with ${deploy_file}"],
  }

  exec { "deploy or update war with ${deploy_file}":
    command     => "/bin/cp -f /opt/nba_ear/${deploy_file} /opt/wildfly_deployments/${application_name}",
    require     => [Class['wildfly'],File['/opt/wildfly_deployments']],
    refreshonly => true,
  }

  class { 'nginx': }

  nginx::resource::upstream { 'nba_v1_wildfly_app':
    members => ['localhost:8080',],
  }

  nginx::resource::vhost { 'api.biodiversity.nl':
    proxy => 'http://nba_v1_wildfly_app/nl.naturalis.nda.service.rest/',
    # proxy => 'http://nba_v1_wildfly_app/nl.naturalis.nda.service.rest/',
  }
  

  # Nginx::Proxy {
  #   ensure => present,
  #   enable => true,
  # }
  #
  # # map proxy to local wildlfy instance
  # nginx::proxy { 'nba_v1':
  #   server_name => 'nba.biodiversity.nl',
  #   location => '/nl.naturalis.nda.service.rest/',
  #   proxy_pass => 'http://localhost:8080/nl.naturalis.nda.service.rest/';
  # }



  # exec {'create jboss admin user':
  #   command    => "/usr/bin/java -jar /opt/jboss/jboss-modules.jar -mp /opt/jboss/modules org.jboss.as.domain-add-user nbaadmin ${admin_password}",
  #   unless     => '/bin/cat /opt/jboss/stanbalone/configuration/mgmt-users.properties | grep nbaadmin',
  #   environment => 'JBOSS_HOME="/opt/jboss"',
  # }

  # @@haproxy::balancermember {$::hostname :
  #   listening_service => $nba_cluster_id,
  #   ports             => 8080,
  #   server_names      => $::hostname,
  #   ipaddresses       => $::ipaddress,
  # }

  # jboss::instance { $application_name :
  #   user          => $application_name,   # Default is jboss
  #   group         => $application_name,   # Default is jboss
  #   createuser    => true,       # Default is true
  #   template      => "all",     # Default is default
  #   binbaddr      => $::ipaddress, # Default is 127.0.0.1
  #   port          => "80",      # Default is 8080
  #   init_timeout  => 10,        # Default is 0
  #   #run_conf      => "site/jboss/myapp/run.conf",  # Default is unset
  #   #conf_dir      => "site/jboss/myapp/conf",      # Default is unset
  #   #deploy_dir    => "site/jboss/myapp/deploy",    # Default is unset
  #   #deployers_dir => "site/jboss/myapp/deployers", # Default is unset
  #  }


}
