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
  #sysctl -w vm.max_map_count=262144

  sysctl {'vm.max_map_count':
    value => '262144',
  }
  ## BUILD STUFF
  file {['/payload','/docker-files','/var/log/docker-nba-builder']:
    ensure => directory,
  }

  package { ['git']: }

  vcsrepo { '/nba-repo':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/naturalis/naturalis_data_api',
    revision => $git_checkout,
    require  => Package['git'],
    notify   => Service['docker-nba-builder'],
  }

  file {'/nba-repo/nl.naturalis.nba.build/build.v2.properties':
    content   => template('nba/build/docker_build.v2.properties.erb'),
    subscribe => Vcsrepo['/nba-repo'],
    require   => Vcsrepo['/nba-repo']
  }

  docker::run{'nba-es-buildsupport':
    image   => 'elasticsearch:2.3.5',
    ports   => ['9310:9300','9210:9200'],
    expose  => ['9300','9200'],
    tag     =>  $elasticsearch_version,
    env     => ['ES_JAVA_OPTS="-Xms512m -Xmx512m"'],
    command => 'elasticsearch -Des.cluster.name="buider-cluster"',
    require => Sysctl['vm.max_map_count'],
  }

  docker::run{'nba-builder':
    image     => 'openjdk:openjdk-8',
    volumes   => ['/nba-repo:/code',
                  '/payload:/payload',
                  '/var/log/docker-nba-builder:/var/log',
                  '/var/log/docker-nba-builder:/code/nl.naturalis.nba.build/log'],
    command   => '/bin/bash -c "/usr/bin/apt-get update ;/usr/bin/apt-get -y install ant ; cd /code/nl.naturalis.nba.build ; ant install-service"',
    depends   => 'nba-es-buildsupport',
    running   => false,
    detach    => false,
    require   => File['/nba-repo/nl.naturalis.nba.build/build.v2.properties'],
  }

  file {'/payload/Dockerfile':
    content => template('nba/docker/wildfly_nba_Dockerfile.erb'),
    require => File['/payload'],
  }


  docker::image{'nba-v2-wildfly-image':
    #image      => "jboss/wildfly:${wildfly_version}",
    docker_dir => '/payload',
    subscribe  => File['/payload/Dockerfile'],
  }

  # docker::run{'nba-v2-wildfly':
  #   image   => 'nba-v2-wildfly-image',
  #   tag     => '',
  #   depends => 'nba-builder',
  #   running => false,
  #   require => Docker::Image['nba-v2-wildfly-image']
  # }


}
