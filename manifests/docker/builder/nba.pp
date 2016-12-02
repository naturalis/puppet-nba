#
#
#
class nba::docker::builder::nba(
  $git_checkout          = 'V2_master',
  $elasticsearch_version = '2.3.4',
  $wildfly_version       = '10.0.0.Final',
){
  #**TODO
  #1 Clone REPO - DONE
  #2 PULL jboss/wildfly AND a elasticsearch 2.3.4
  #3 Create image for build - ABANDOND
  #4 Produce war and config - DONE
  #5 change config
  #6 create image with nba and config script


  ## BUILD STUFF
  file {['/payload','/docker-files','var/log/docker-nba-builder']:
    ensure => directory,
  }

  package { ['git']: }

  vcsrepo { '/nba-repo':
    ensure   => latest,
    provider => 'git',
    source   => 'https://github.com/naturalis/naturalis_data_api',
    revision => $git_checkout,
    require  => Package['git'],
  }

  file {'/nba-repo/nl.naturalis.nba.build/build.v2.properties':
    content   => template('nba/build/docker_build.v2.properties.erb'),
    subscribe => Vcsrepo['/nba-repo'],
    require   => Vcsrepo['/nba-repo']
  }

  file {'/nba-repo/nl.naturalis.nba.build/log':
    ensure    => link,
    target    => 'var/log/docker-nba-builder',
    subscribe => Vcsrepo['/nba-repo'],
    require   => Vcsrepo['/nba-repo']
  }

  # docker::image{'nba-builder':
  #   docker_file => '/docker-files/nba-builder',
  #   subscribe   => [Vcsrepo['/nba-repo'],
  #                   File['/nba-repo/nl.naturalis.nba.build/build.v2.properties']
  #                   File['/docker-files/nba-builder'],
  #   ],
  # }
  #
  # file {'/docker-files/docker-builder':
  #   ensure  => present,
  #   content => 'RUN yum -y install ant'
  # }
  #ES_HEAP_SIZE=512mb
  # RUN STUFF

  docker::run{'nba-es-buildsupport':
    image => 'elasticsearch',
    ports => '9310:9300',
    tag   =>  $elasticsearch_version,
    env   => ['ES_HEAP_SIZE=512m'],
    run   => 'elasticsearch -Des.cluster.name="buider-cluster"',
  }

  docker::run{'nba-builder':
    tag       => 'openjdk-8',
    image     => 'openjdk',
    volumes   => ['/nba-repo:/code','/payload:/payload','var/log/docker-nba-builder:/var/log'],
    command   => '/bin/bash -c "/usr/bin/apt-get update ; /usr/bin/apt-get -y install ant ; cd /code/nl.naturalis.nba.build ; ant install-service"',
    #depends   => 'nba-es-buildsupport',
    subscribe => Vcsrepo['/nba-repo'],
    require   => File['/nba-repo/nl.naturalis.nba.build/build.v2.properties']
  }



}
