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
  $admin_password     = 'nba',
  $application_name   = 'nba',
  $port               = '8080',
  $extra_users_hash   = undef,
  $nba_config_dir     = '/etc/nba',
  $es_host_ip         = '127.0.0.1',
  $es_transport_port  = '9300'
){

  if $nba_cluster_id == 'changeme' { fail('Change the variable nba_cluster_name to a propper one') }

  if $extra_users_hash {
    create_resources('base::users', parseyaml($extra_users_hash))
  }

  package {'subversion' : }

  package {'openjdk-7-jdk' :} ->

  class { 'wildfly':
    bind_address            => $::ipaddress,
    use_web_download        => true,
    bind_address_management => 'localhost',
  } ->

  exec {'create wildfly admin user':
    command => "/bin/sh /opt/wildfly/bin/add-user.sh --silent nbaadmin ${admin_password} ",
    unless  => '/bin/cat /opt/wildfly/stanbalone/configuration/mgmt-users.properties | grep nbaadmin',
  } ->

  exec {'set nba config dir':
    command => "/bin/sh /opt/wildfly/bin/jboss-cli.sh --connect --command='/system-property=nl.naturalis.nda.conf.dir:add(value=${nba_config_dir})'",
    unless  => "/bin/sh /opt/wildfly/bin/jboss-cli.sh --connect --command='/system-property=nl.naturalis.nda.conf.dir:read-resource'|/bin/grep result| /bin/grep '${nba_config_dir}'",
  } ->

  class { 'wildfly::deploy' :
    filelocation => 'puppet:///modules/nba',
    filename     => 'nl.naturalis.nda.ear',
    notify       => Service['wildfly'],
  }


  # exec {'create jboss admin user':
  #   command    => "/usr/bin/java -jar /opt/jboss/jboss-modules.jar -mp /opt/jboss/modules org.jboss.as.domain-add-user nbaadmin ${admin_password}",
  #   unless     => '/bin/cat /opt/jboss/stanbalone/configuration/mgmt-users.properties | grep nbaadmin',
  #   environment => 'JBOSS_HOME="/opt/jboss"',
  # }

  @@haproxy::balancermember {$::hostname :
    listening_service => $nba_cluster_id,
    ports             => $port,
    server_names      => $::hostname,
    ipaddresses       => $::ipaddress,
  }

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
