#
#
#
class nba::all_in_one::lb(
  $vhost = {
    'apitest.biodiversitydata.nl' => {'www_root' => '/var/www/apitest.biodiversitydata.nl'},
    'datatest.biodiversitydata.nl' => {'proxy' => 'http://purl/purl'}
  },
  $location = {
    'api_v0' => {'location' => '/v0','vhost'=>'apitest.biodiversitydata.nl','proxy'=>'http://avpi_v0/v0'}
  },
  $upstream = {
      'api_v0' => {'members'=> [ $::ipaddress ]},
      'purl' => {'members'=> [ $::ipaddress ]}
  },
  $files = {
    '/var/www' => {'type' => 'dir'},
    '/var/www/apitest.biodiversitydata.nl' => {'type' => 'dir'}
  }
  ){

  $log_default = { format_log => 'json'}
  Anchor['nginx::begin']
  ->
  class { 'nginx::config':
    log_format => {
      json => '{ "@timestamp": "$time_iso8601", "@fields": { "remote_addr": "$remote_addr", "remote_user": "$remote_user", "body_bytes_sent": "$body_bytes_sent", "request_time": "$request_time","status": "$status", "request": "$request", "request_method": "$request_method", "http_referrer": "$http_referer", "http_user_agent": "$http_user_agent" } }'
    }
  }

  class {'nginx': }

  create_resources(nba::lb::wwwfiles,$::files,{})
  create_resources(nginx::resource::vhost,$::vhost,$log_default)
  create_resources(nginx::resource::location,$::location,{})
  create_resources(nginx::resource::upstream,$::upstream,{})
}
