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

  $buildname = downcase($git_checkout)
  $timestamp = strftime('%Y.%m.%d-%H.%M')
  $image_name = "nba-wildfly-${buildname}"

  sysctl {'vm.max_map_count':
    value => '262144',
  }
  ## BUILD STUFF
  file {["/payload-${buildname}",'/docker-files','/var/log/docker-nba-builder']:
    ensure => directory,
  }

  package { ['git']: }

  vcsrepo { "/nba-repo-${buildname}" :
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/naturalis/naturalis_data_api',
    revision => "${git_checkout}",
    require  => Package['git'],
    notify   => Exec["trigger build of nba-${buildname}"],
  }

  file {"/nba-repo-${buildname}/nl.naturalis.nba.build/build.v2.properties" :
    content   => template('nba/build/docker_build.v2.properties.erb'),
    subscribe => Vcsrepo["/nba-repo-${buildname}"],
    require   => Vcsrepo["/nba-repo-${buildname}"]
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
    image   => 'openjdk:8',
    volumes => ["/nba-repo-${buildname}:/code",
                  "/payload-${buildname}:/payload",
                  '/var/log/docker-nba-builder:/var/log',
                  '/var/log/docker-nba-builder:/code/nl.naturalis.nba.build/log'],
    command => '/bin/bash -c "/usr/bin/apt-get update ;/usr/bin/apt-get -y install ant ; cd /code/nl.naturalis.nba.build ; ant install-service"',
    depends => 'nba-es-buildsupport',
    running => false,
    detach  => false,
    require => File["/nba-repo-${buildname}/nl.naturalis.nba.build/build.v2.properties"],
    # maybe pull on start to ensure latest image
  }

  file {"/payload-${buildname}/Dockerfile" :
    content => template('nba/docker/wildfly_nba_Dockerfile.erb'),
    require => File["/payload-${buildname}"],
  }


  exec {"trigger build of nba-${buildname}" :
    command     => "/usr/sbin/service docker-nba-builder start",
    refreshonly => true,
    require     => Docker::Run['nba-builder'],
    notify      => Exec["build docker image for ${image_name}"]
  }
  # docker::image{"nba-${buildname}-wildfly-image":
  #   #image      => "jboss/wildfly:${wildfly_version}",
  #   docker_dir => "/payload-${buildname}",
  #   subscribe  => File["/payload-${buildname}/Dockerfile"],
  #   notify     => Exec["cleanup ${buildname} payload files"],
  # }
  exec {"build docker image for ${image_name}" :
    command     => "/usr/bin/docker build --pull -t ${image_name}:${timestamp} /payload-${buildname}",
    refreshonly => true,
    onlyif      => "/usr/bin/test -f /payload-${buildname}/nba.war",
    require     => File["/payload-${buildname}/Dockerfile"],
    notify      => [Exec["tag repository with ${image_name}:${timestamp}"],
                    Exec["tag repository with ${image_name}:latest"]],
  }

  exec {"cleanup ${buildname} payload files" :
    command     => "/bin/rm -fr /payload-${buildname}/*",
    refreshonly => true,
    notify      => Exec["cleanup ${buildname} repo"],
  }

  exec {"cleanup ${buildname} repo" :
    command     => "/usr/bin/git checkout ${git_checkout} ; /usr/bin/git reset --hard",
    cwd         => "/nba-repo-${buildname}",
    refreshonly => true,
  }

  exec {"tag repository with ${image_name}:${timestamp}" :
    command     => "/usr/bin/docker tag ${image_name}:${timestamp} localhost:5000/${image_name}:${timestamp}",
    refreshonly => true,
    notify      => Exec["push to repository/${image_name}:${timestamp}"],
  }

  exec {"tag repository with ${image_name}:latest" :
    command     => "/usr/bin/docker tag ${image_name}:${timestamp} localhost:5000/${image_name}:latest",
    refreshonly => true,
    notify      => Exec["push to repository/${image_name}:latest"],
  }

  exec {"push to repository/${image_name}:${timestamp}" :
    command     => "/usr/bin/docker push localhost:5000/${image_name}:${timestamp}",
    refreshonly => true,
  }

  exec {"push to repository/${image_name}:latest" :
    command     => "/usr/bin/docker push localhost:5000/${image_name}:latest",
    refreshonly => true,
  }

  notify { $timestamp : }


  # docker::run{'nba-v2-wildfly':
  #   image   => 'nba-v2-wildfly-image',
  #   tag     => '',
  #   depends => 'nba-builder',
  #   running => false,
  #   require => Docker::Image['nba-v2-wildfly-image']
  # }


}
