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
    '/data',
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
      command => '/bin/sh /opt/nba-import/sh/bootstrap-nda.sh',
      unless  => '/usr/bin/curl -s -XGET localhost:9200/_cat/indices | grep nda',
      cwd     => '/opt/nba-import/sh',
    }

    exec { 'import - crs':
      command   => '/bin/mv /data/upload/crs/* /data/import/crs/ && /bin/sh /opt/nba-import/sh/import-crs.sh&',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/crs/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
      cwd       => '/opt/nba-import/sh',
      notify    => Exec['set nda import pid'],
    }

    exec { 'import - col':
      command   => '/bin/mv /data/upload/col/* /data/import/col/ && /bin/sh /opt/nba-import/sh/import-col.sh&',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/col/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
      cwd       => '/opt/nba-import/sh',
      notify    => Exec['set nda import pid'],
    }

    exec { 'import - brahms':
      command   => '/bin/mv /data/upload/brahms/* /data/import/brahms/ && /bin/sh /opt/nba-import/sh/import-brahms.sh&',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/brahms/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
      cwd       => '/opt/nba-import/sh',
      notify    => Exec['set nda import pid'],
    }

    exec { 'import - nsr':
      command   => '/bin/mv /data/upload/nsr/* /data/import/nsr/ && /bin/sh /opt/nba-import/sh/import-nsr.sh&',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/nsr/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
      cwd       => '/opt/nba-import/sh',
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
      unless    => ['/bin/ps aux | grep java | grep import | grep -v grep','/bin/ls /var/run/nda-import.pid  2>&1 | grep cannot'],
    }

}
