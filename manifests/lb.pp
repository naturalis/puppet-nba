#
#
#
class nba::lb (
  $vhost            = undef,
  $app_servers_hash = {}
){

  $www_root = "/var/www/${vhost}"

  file { ['/var/www',$www_root] :
    ensure => directory,
  }

  file { "${www_root}/index.html" :
    ensure  => present,
    content => '<html><h1>hoi</h1></html>',
    require => File[$www_root],
  }

  file { "${www_root}/404.html" :
    ensure  => present,
    content => template('nba/404.html.erb'),
    require => File[$www_root],
  }

  class { 'nginx': }

  nginx::resource::vhost { $vhost:
    www_root            => $www_root,
    location_cfg_append => { 'error_page  404' => '/404.html' },
  }


  create_resources(nba::lb::sites,$app_servers_hash,{})

}
