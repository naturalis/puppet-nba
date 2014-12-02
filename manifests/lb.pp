#
#
#
class nba::lb (
  $vhost            = undef,
  $app_servers_hash = {}
){

  $www_root = "/var/www/${vhost}"

  file { $www_root :
    ensure => directory,
  }

  file { "${www_root}/index.html" :
    ensure  => present,
    content => '<html><h1>hoi</h1></html>',
    require => File[$www_root],
  }

  class { 'nginx': }

  nginx::resource::vhost { $vhost:
    www_root => $www_root,
  }

  create_resources(nba::lb::sites,$app_servers_hash,{})

}
