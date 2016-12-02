#
#
### Creates local docker registry to server NBA images
class nba::docker::builder::registry(
  $registry_name = 'nba-registry',
  $listen_port   = '5000',
  )
{
  include 'docker'

  file { ["/${registry_name}","/var/log/docker-${registry_name}"] :
    ensure => directory,
  }

  docker::run {$registry_name:
    image   => 'registry:2',
    ports   => "${listen_port}:5000",
    volumes => ["/${registry_name}:/var/lib/registry",
                "/var/log/docker-${registry_name}:/var/log"],
    require => [File["/${registry_name}"],
                File["/var/log/docker-${registry_name}"]],
  }

}
