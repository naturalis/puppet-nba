#
#Class for importserver
#

class nba::import()
{


  # have upload dirs for each section
  # check if there are files
  # if there are new files
  #   track them is lsof dir/*  /usr/bin/lsof ${dir}/* | grep -v COMMAND
  #   wait until lsof is empty
  #   move files to directory for import this ~>
  #   trigger import

  # no need for concurency checking
  exec {'check if there are new files':
    command => '/bin/echo "new files"',
    onlyif  => '/bin/ls /opt/boe/*',
    notify  => Exec['wait for it'],
  }

  exec {'wait for it':
    command     => '/bin/mv /opt/boe/* /opt/data',
    unless      => '/usr/bin/lsof /opt/boe/* | grep -v COMMAND',
    notify      => Exec['importit'],
    refreshonly => true,
  }

  exec { 'importit':
    command     => '/bin/echo "start import" > /opt/data/info.txt',
    refreshonly => true,
  }
}
