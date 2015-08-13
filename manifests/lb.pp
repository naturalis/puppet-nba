#
#
#
#
#
#
class nba::lb (
  $vhost       = {},
  $location    = {},
  $upstream    = {},
  $files       = {}
){

  class { 'nginx': }

  # file { $directories :
  #   ensure => directory,
  # }
  #
  # if ($htmlfiles != []) {
  #   file { $htmlfiles :
  #     ensure  => present,
  #     path    => "/var/www/${htmlfiles}",
  #     content => template("nba/${htmlfiles}.erb"),
  #     require => File[$directories],
  #   }
  # }

  create_resources(nba::lb::wwwfiles,$files,{})
  create_resources(nginx::resource::vhost,$vhost,{})
  create_resources(nginx::resource::location,$location,{})
  create_resources(nginx::resource::upstream,$upstream,{})


  #nba::lb::vhosts { $vhost : }
  #create_resources(nba::lb::vhosts,$vhost,{})
  #create_resources(nba::lb::sites,$app_servers_hash,{})

}
