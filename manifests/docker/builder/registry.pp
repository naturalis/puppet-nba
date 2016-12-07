#
#
### Creates local docker registry to server NBA images
class nba::docker::builder::registry(
  $registry_name = 'nba-registry',
  $listen_port   = '5000',
  )
{
  include 'docker'

  file { ["/${registry_name}","/var/log/docker-${registry_name}","/${registry_name}-certs"] :
    ensure => directory,
  }

  docker::run {$registry_name:
    image            => 'registry:2',
    ports            => "${listen_port}:5000",
    volumes          => ["/${registry_name}:/var/lib/registry",
                        "/var/log/docker-${registry_name}:/var/log",
                        "/${registry_name}-certs:/certs"],
    env              => ['REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt','REGISTRY_HTTP_TLS_KEY=/certs/domain.key']
    extra_parameters => [ '--restart=always' ],
    require          => [File["/${registry_name}"],
                        File["/var/log/docker-${registry_name}"]],
  }

}
