#
#
#
define nba::lb::sites(
  $name     = undef,
  $members  = undef,
  $location = undef,
  $endpoint = '/'
){

  nginx::resource::upstream { $name:
    members => $members,
  }

  nginx::resource::location{ '162_13_138_109_linneaus_ng':
    location => $location,
    vhost    => $nba::vhost,
    proxy    => "http://${name}${endpoint}",
  }

}
