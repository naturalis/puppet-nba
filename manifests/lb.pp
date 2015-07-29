#
#
#
class nba::lb (
  $vhost       = {},
  $location    = {},
  $upstream    = {},
  $directories = ['/var/www'],
  $htmlfiles   = [],
){

  class { 'nginx': }

  file { $directories :
    ensure => directory,
  }

  file { $htmlfiles :
    ensure  => present,
    path    => "/var/www/${htmlfiles}",
    content => template("${htmlfiles}.erb"),
    require => File[$directories],
  }

  create_resources(nginx::resource::vhost,$vhost,{})
  create_resources(nginx::resource::location,$location,{})
  create_resources(nginx::resource::upstream,$upstream,{})


  #nba::lb::vhosts { $vhost : }
  #create_resources(nba::lb::vhosts,$vhost,{})
  #create_resources(nba::lb::sites,$app_servers_hash,{})

}
