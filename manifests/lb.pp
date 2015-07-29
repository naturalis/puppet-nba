#
#
#
class nba::lb (
  $vhost            = [],
  $app_servers_hash = {}
){

  class { 'nginx': }
  nba::lb::vhosts { $vhost : }
  #create_resources(nba::lb::vhosts,$vhost,{})
  create_resources(nba::lb::sites,$app_servers_hash,{})

}
