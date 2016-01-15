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

  $log_default = { format_log => 'json'}
  Anchor['::nginx::begin']
  ->
  class { '::nginx::config':
    log_format => {
      json => '{ "@timestamp": "$time_iso8601", "@fields": { "remote_addr": "$remote_addr", "remote_user": "$remote_user", "body_bytes_sent": "$body_bytes_sent", "request_time": "$request_time","status": "$status", "request": "$request", "request_method": "$request_method", "http_referrer": "$http_referer", "http_user_agent": "$http_user_agent" } }'
    }
  }

  #access_log
  # file { $directories :
  #   ensure => directory,
  # }
  #
  # if ($htmlfiles != []) {
  #   file { $htmlfiles :
  #     ensure  => present,dfa
  #     path    => "/var/www/${htmlfiles}",
  #     content => template("nba/${htmlfiles}.erb"),
  #     require => File[$directories],
  #   }
  # }
  #

  create_resources(nba::lb::wwwfiles,$files,{})
  create_resources(nginx::resource::vhost,$vhost,$log_default)
  create_resources(nginx::resource::location,$location,{})
  create_resources(nginx::resource::upstream,$upstream,{})


  #nba::lb::vhosts { $vhost : }
  #create_resources(nba::lb::vhosts,$vhost,{})
  #create_resources(nba::lb::sites,$app_servers_hash,{})

}
