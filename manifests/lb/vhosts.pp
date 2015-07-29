#
#
#
define nba::lb::vhosts(
){


  $www_root = "/var/www/${name}"

  file { ['/var/www',$name] :
    ensure => directory,
  }

  file { "${www_root}/index.html" :
    ensure  => present,
    content => template('nba/404.html.erb'),
    require => File[$www_root],
  }

  file { "${www_root}/404.html" :
    ensure  => present,
    content => template('nba/404.html.erb'),
    require => File[$www_root],
  }

  nginx::resource::vhost { $name:
    www_root             => $www_root,
    use_default_location => false,
    location_cfg_append  => {
      'error_page  404 ' => '/404.html'
      #'rewrite'          => '^ http://$server_name/404.html'
    },
  }



}
