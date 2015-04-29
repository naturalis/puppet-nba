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

  nginx::resource::location{ $location :
    location => $location,
    vhost    => $vhost,
    proxy    => "http://${name}${endpoint}",
  }

}
