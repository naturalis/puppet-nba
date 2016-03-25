#
#
#
class  nba::roles::workbench()

{

  package {['git','ant','ivy']:
    ensure => installed,
  }

  exec {'add ivy env':
      command => '/bin/echo IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/ >> /etc/environment',
      unless  => '/bin/grep /etc/environment -e IVY_HOME',
  }

  file_line {'ivy_home':
    path  => '/etc/environment',
    line  => 'IVY_HOME=/usr/share/maven-repo/org/apache/ivy/ivy/2.3.0/',
    match => '^IVY_HOME',
  }

  class { 'elasticsearch':
    package_url   => 'https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/2.2.1/elasticsearch-2.2.1.deb',
    java_install  => true,
    config        => {
      'node.name'                            => $::hostname,
      'node.master'                          => true,
      'node.data'                            => true,
      'cluster.name'                         => 'Test NBA Workbench Single Node',
      'index.number_of_shards'               => 3,
      'index.number_of_replicas'             => 0,
      'network.host'                         => '127.0.0.1',
    },
    init_defaults => {
      'ES_HEAP_SIZE' => "2g"
    }
  }

  elasticsearch::instance { "Elasticsearch-${::hostname}-node":  }

  $kibana_version = '4.4.2'
  $elasticsearch_host = '127.0.0.1'
  $kibana_link = "https://download.elastic.co/kibana/kibana/kibana-${kibana_version}-linux-x64.tar.gz"

  staging::deploy { "kibana-${kibana_version}-linux-x64.tar.gz":
    source  => $kibana_link,
    target  => '/opt/',
    require => Class['elasticsearch'],
  }

  exec {'install sense':
    command => "/opt/kibana-${kibana_version}-linux-x64/bin/kibana plugin --install elastic/sense",
    unless  => "/usr/bin/test -d /opt/kibana-${kibana_version}-linux-x64/installedPlugins/sense",
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
    before  => Service['kibana'],
  }

  file_line {'kibana_es_host_config':
    path    => "/opt/kibana-${kibana_version}-linux-x64/config/kibana.yml",
    line    => "elasticsearch.url: http://${elasticsearch_host}:9200",
    match   => '^elasticsearch.url',
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
  }

  # file_line {'server_host_config':
  #   path    => "/opt/kibana-${kibana_version}-linux-x64/config/kibana.yml",
  #   line    => 'server.host: 127.0.0.1',
  #   match   => '^server.host',
  #   require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
  # }

  file { 'kibana service init':
    content => template('role_logging/kibana/init.erb'),
    path    => '/etc/init.d/kibana',
    mode    => '0775',
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
  }

  file {'kibana log directory':
    ensure => directory,
    path   => '/var/log/kibana',
    before => Service['kibana']
  }

  file {'kibana log rotate':
    content => template('role_logging/kibana/logrotate.erb'),
    path    => '/etc/logrotate.d/kibana',
  }

  service {'kibana':
    ensure    => running,
    subscribe => File['kibana service init'],
  }

}
