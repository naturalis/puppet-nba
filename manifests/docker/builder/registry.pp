#
#
### Creates local docker registry to server NBA images
class nba::docker::builder::registry()
{
  include 'docker'

  file { '/nba-registry' :
    ensure => directory,
  }

  docker::run {'nba-registry':
    image   => 'registry:2',
    ports   => '5000:5000',
    volumes => ['/nba-registry:/var/lib/registry'],
    require => File['/nba-registry'],
  }

}
