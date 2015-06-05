#
#Class for importserver
#

class nba::import()
{
  # exec {'importit':
  #   command   => '/bin/mv /opt/boe/* /opt/data/ && /bin/echo "importing files"',
  #   logoutput => true,
  #   unless    => '/usr/bin/lsof /opt/boe/*  2>&1 | grep "status\|COMMAND"'
  # }

  file {[
    '/data/upload',
    '/data/upload/crs',
    '/data/upload/col',
    '/data/upload/brahms',
    '/data/upload/nsr',
    '/data/import-logs']:
    ensure => 'directory',
    owner  => 'root',
    group  => 'wheel',
    mode   => '0770',
    }

    file {[
      '/data/import',
      '/data/import/crs',
      '/data/import/col',
      '/data/import/brahms',
      '/data/import/nsr']:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      require => [File['/data']],
    }

    exec { 'import - bootstrap':
      command => '/bin/sh /data/nba-import/sh/bootstrap-nda.sh',
      unless  => '/usr/bin/curl -s -XGET localhost:9200/_cat/indices | grep nda',
      cwd     => '/data/nba-import/sh',
    }

    exec { 'import - crs':
      command   => '/bin/mv /data/upload/crs/* /data/import/crs/ && /bin/sh /data/nba-import/sh/import-crs.sh&',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/crs/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
      cwd       => '/data/nba-import/sh',
      notify    => Exec['set nda import pid'],
    }

    exec { 'import - col':
      command   => '/bin/mv /data/upload/col/* /data/import/col/ && /bin/sh /data/nba-import/sh/import-col.sh&',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/col/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
      cwd       => '/data/nba-import/sh',
      notify    => Exec['set nda import pid'],
    }

    exec { 'import - brahms':
      command   => '/bin/mv /data/upload/brahms/* /data/import/brahms',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/brahms/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
      cwd       => '/data/nba-import/sh',
      notify    => Exec['set nda import pid'],
    }

    exec { 'import - nsr':
      command   => '/bin/mv /data/upload/nsr/* /data/import/nsr/ && /bin/sh /data/nba-import/sh/import-nsr.sh&',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/nsr/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
      cwd       => '/data/nba-import/sh',
      notify    => Exec['set nda import pid'],
    }

    exec { 'set nda import pid':
      command     => '/usr/bin/touch /var/run/nda-import.pid',
      creates     => '/var/run/nda-import.pid',
      refreshonly => true,
    }

    exec { 'take elasticsearch snapshot':
      command   => '/bin/echo taking snapshot tbi && /bin/rm /var/run/nda-import.pid',
      logoutput => true,
      unless    => ['/bin/ps aux | grep java | grep import | grep -v logstash | grep -v grep','/bin/ls /var/run/nda-import.pid  2>&1 | grep cannot'],
      notify    => Es_snapshot['make_snapshot']
    }

    $timestamp = strftime('%Y.%m.%d.%H.%M')

    es_snapshot { 'make_snapshot':
      snapshot_name => "snapshot_${timestamp}",
      repo          => 'import',
      ip            => '127.0.0.1',
      port          => '9200',
      require       => Es_repo['import'],
      refreshonly   => true,
    }

    es_repo { 'import':
      ensure   => present,
      type     => 'fs',
      settings => {
        'location' => '/snapshot',
        'compress' => true,
      },
      ip       => '127.0.0.1',
      port     => '9200',
      require  => File['/snapshot'],
    }

    file{ '/snapshot':
      ensure => 'directory',
      owner  => 'elasticsearch',
      group  => 'elasticsearch',
      mode   => '0777',
    }

}
