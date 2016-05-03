#
#
#
class nba::all_in_one::kibana(
  $kibana_version = '4.5.0',
){

  $kibana_link = "https://download.elastic.co/kibana/kibana/kibana-${kibana_version}-linux-x64.tar.gz"

  staging::deploy { "kibana-${kibana_version}-linux-x64.tar.gz":
    source => $kibana_link,
    target => '/opt/'
  }

  file_line {'disable kibana':
    path    => "/opt/kibana-${kibana_version}-linux-x64/config/kibana.yml",
    line    => 'kibana.enabled: false',
    match   => '^kibana.enabled',
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
  }

  file_line {'disable elasticsearch for kibana':
    path    => "/opt/kibana-${kibana_version}-linux-x64/config/kibana.yml",
    line    => 'elasticsearch.enabled: false',
    match   => '^selasticsearch.enabled',
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
  }

  file { 'kibana service init':
    content => template('nba/kibana/init.erb'),
    path    => '/etc/init.d/kibana',
    mode    => '0775',
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
  }

  file {'kibana log rotate':
    content => template('nba/kibana/logrotate.erb'),
    path    => '/etc/logrotate.d/kibana',
  }

  file {'kibana log directory':
    ensure => directory,
    path   => '/var/log/kibana',
    before => Exec['install sense'],
  }

  exec {'install sense':
    command => "/opt/kibana-${kibana_version}-linux-x64/bin/kibana plugin --install elastic/sense",
    require => Staging::Deploy["kibana-${kibana_version}-linux-x64.tar.gz"],
    before  => Service['kibana'],
  }

  service {'kibana':
    ensure    => running,
    subscribe => File['kibana service init'],
  }

}
