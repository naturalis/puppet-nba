#
#Class for importserver
#

class nba::import()
{
  exec {'importit':
    command   => '/bin/mv /opt/boe/* /opt/data/ && /bin/echo "importing files"',
    logoutput => true,
    unless    => '/usr/bin/lsof /opt/boe/*  2>&1 | grep "status\|COMMAND"'
  }

  file {[
    '/data',
    '/data/upload',
    '/data/upload/crs',
    '/data/upload/col',
    '/data/upload/brahms',
    '/data/upload/nsr',
    '/data/import-logs']:
    ensure => Directory,
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
      ensure => Directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }
}
