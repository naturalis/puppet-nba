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

  if ($endpoint == '/') {

    nginx::resource::location{ "${vhost}-default" :
      location => $location,
      vhost    => $vhost,
      proxy    => "http://${name}${endpoint}",
    }
    
  }else{

    if !defined(Nginx::Resource::Location["${vhost}-default"]) {
      nginx::resource::location{ "${vhost}-default" :
        before => Nginx::Resource::Location["${vhost}-${location}"],
      }
    }

    nginx::resource::location{ "${vhost}-${location}" :
      location => $location,
      vhost    => $vhost,
      proxy    => "http://${name}${endpoint}",
    }

  }

}
