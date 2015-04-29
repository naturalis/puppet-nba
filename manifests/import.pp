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
    }

    exec { 'import - crs':
      command   => '/bin/mv /data/upload/crs/* /data/import/crs/ && /bin/sh /opt/nba-import/sh/import-crs.sh&',
      logoutput => false,
      unless    => '/usr/bin/lsof /data/upload/crs/*  2>&1 | grep "status\|COMMAND"',
      require   => Exec['import - bootstrap'],
    }
}
