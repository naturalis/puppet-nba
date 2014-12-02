#
#
#
define nba::lb::sites(
  $members  = undef,
  $location = undef,
  $vhost    = undef,
  $endpoint = '/'
){

  nginx::resource::upstream { $name:
    members => $members,
  }

  nginx::resource::location{ '162_13_138_109_linneaus_ng':
    location => $location,
    vhost    => $vhost,
    proxy    => "http://${name}${endpoint}",
  }

}
