#
#
#
class  nba::roles::purl (
  $wildfly_console_password,
){

  host {'api.biodiversitydata.nl':
    ip => '10.42.1.192'
  }

  file {'/opt/wildfly_deployments':
    ensure => directory,
    mode   => '0777',
    before => Class['nba']
  }

  file {'/etc/purl':
    ensure  => directory,
    mode    => '0750',
    require => Class['nba'],
    owner   => 'wildfly',
    group   => 'wildfly',
  }

  file {'/etc/purl/purl.properties':
    ensure  => present,
    mode    => '0750',
    require => File['/etc/purl'],
    owner   => 'wildfly',
    group   => 'wildfly',
    content => template('nba/purl/purl.properties.erb')
  }


  $logging_properties = {
    'logger.level' => { value => 'INFO'},
    'logger.handlers' => { value => 'CONSOLE,FILE'},
    'logger.nl.naturalis.purl.level' => { value => 'DEBUG'},
    'logger.nl.naturalis.purl.useParentHandlers' => { value => true},
    'logger.jacorb.level' => { value => 'WARN'},
    'logger.jacorb.useParentHandlers' => { value => true},
    'logger.com.arjuna.level' => { value => 'WARN'},
    'logger.com.arjuna.useParentHandlers' => { value => true},
    'logger.org.apache.tomcat.util.modeler.level' => { value => 'WARN'},
    'logger.org.apache.tomcat.util.modeler.useParentHandlers' => { value => true},
    'logger.org.jboss.as.config.level' => { value => 'DEBUG'},
    'logger.org.jboss.as.config.useParentHandlers' => { value => true},
    'logger.jacorb.config.level' => { value => 'ERROR'},
    'logger.jacorb.config.useParentHandlers' => { value => true},
    'logger.sun.rmi.level' => { value => 'WARN'},
    'logger.sun.rmi.useParentHandlers' => { value => true},
    'handler.CONSOLE' => { value => 'org.jboss.logmanager.handlers.ConsoleHandler'},
    'handler.CONSOLE.level' => { value => 'INFO'},
    'handler.CONSOLE.formatter' => { value => 'COLOR-PATTERN'},
    'handler.CONSOLE.properties' => { value => 'autoFlush,target,enabled'},
    'handler.CONSOLE.autoFlush' => { value => true},
    'handler.CONSOLE.target' => { value => 'SYSTEM_OUT'},
    'handler.CONSOLE.enabled' => { value => true},
    'handler.FILE' => { value => 'org.jboss.logmanager.handlers.PeriodicRotatingFileHandler'},
    'handler.FILE.level' => { value => 'ALL'},
    'handler.FILE.formatter' => { value => 'PATTERN'},
    'handler.FILE.properties' => { value => 'append,autoFlush,enabled,suffix,fileName'},
    'handler.FILE.constructorProperties' => { value => 'fileName,append'},
    'handler.FILE.append' => { value => true},
    'handler.FILE.autoFlush' => { value => true},
    'handler.FILE.enabled' => { value => true},
    'handler.FILE.suffix' => { value => '.yyyy-MM-dd'},
    'handler.FILE.fileName' => { value => '/opt/wildfly/standalone/log/server.log'},
    'formatter.PATTERN' => { value => 'org.jboss.logmanager.formatters.PatternFormatter'},
    'formatter.PATTERN.properties' => { value => 'pattern'},
    'formatter.PATTERN.pattern' => { value => '%d{yyyy-MM-dd HH\:mm\:ss,SSS} %-5p [%c] (%t) %s%E%n'},
    'formatter.COLOR-PATTERN' => { value => 'org.jboss.logmanager.formatters.PatternFormatter'},
    'formatter.COLOR-PATTERN.properties' => { value => 'pattern'},
    'formatter.COLOR-PATTERN.pattern' => { value => '%K{level}%d{HH\:mm\:ss,SSS} %-5p [%c] (%t) %s%E%n'}
  }

  # package {['git','ant','ivy','openjdk-7-jdk']:
  #   ensure => installed,
  #   before => Class['nba']
  # }

  # exec {'add ivy env':
  #     command => '/bin/echo \'IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/\' >> /etc/environment',
  #     unless  => '/bin/grep environment -e IVY_HOME',
  # }
  class { 'nba':
    nba_cluster_id      => 'something random because of dev',
    console_listen_ip   => '127.0.0.1',
    admin_password      => $wildfly_console_password,
    extra_users_hash    => undef,
    nba_config_dir      => '/etc/nba',
    es_transport_port   => '9300',
    index_name          => 'nda',
    wildfly_debug       => true,
    wildfly_xmx         => '1024m',
    wildfly_xms         => '256m',
    wildlfy_maxpermsize => '512m',
    wildfly_sys_prop    => {
      'nl.naturalis.purl.conf.dir' => '/etc/purl'
    },
    install_java        => true,
    wildfly_logging     => $logging_properties,
    #stage               => wildfly,
  }

  file { '/tmp/purl.war':
    ensure => present,
    source => 'puppet:///modules/nba/purl.war',
    owner  => 'wildfly',
    group  => 'wildfly',
    notify => Exec['deploy or update war with purl.war'],
  }

  exec { 'deploy or update war with purl.war':
    command     => '/bin/cp -f /tmp/purl.war /opt/wildfly_deployments/purl.war',
    require     => [Class['nba'],File['/opt/wildfly_deployments']],
    refreshonly => true,
  }


}
