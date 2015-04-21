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
}
