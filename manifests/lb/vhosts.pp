#
#
#
define nba::lb::vhosts(
){


  $www_root = "/var/www/${name}"

  file { $www_root :
    ensure  => directory,
    require => File['/var/www'],
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
