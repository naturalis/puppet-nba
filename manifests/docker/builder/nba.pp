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
  $timestamp = strftime('%Y.%m.%d-%k.%M')

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
    revision => $git_checkout,
    require  => Package['git'],
    notify   => Exec[{"trigger build of nba-${buildname}"],
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
    notify  => Exec["cleanup ${buildname} repo"],
    # maybe pull on start to ensure latest image
  }

  file {"/payload-${buildname}/Dockerfile" :
    content => template('nba/docker/wildfly_nba_Dockerfile.erb'),
    require => File["/payload-${buildname}"],
  }


  exec {"trigger build of nba-${buildname}" :
    command     => "/usr/sbin/service restart docker-nba-builder",
    refreshonly => true,
    require     => Docker::Run['nba-builder'],
    notify      => Exec["build docker image for ${buildname}"]
  }
  # docker::image{"nba-${buildname}-wildfly-image":
  #   #image      => "jboss/wildfly:${wildfly_version}",
  #   docker_dir => "/payload-${buildname}",
  #   subscribe  => File["/payload-${buildname}/Dockerfile"],
  #   notify     => Exec["cleanup ${buildname} payload files"],
  # }
  exec {"build docker image for ${buildname}" :
    command     => "/usr/bin/docker build -t nba-${buildname}-wildfly /payload-${buildname}",
    refreshonly => true,
    onlyif      => "/usr/bin/test -f /payload-${buildname}/nba.war",
    require     => File["/payload-${buildname}/Dockerfile"],
    #subscribe   => Service['docker-nba-builder'],
  }

  exec {"cleanup ${buildname} payload files" :
    command     => "/bin/rm -fr /payload-${buildname}/*",
    refreshonly => true,
  }

  exec {"cleanup ${buildname} repo" :
    command     => '/usr/bin/git reset --hard',
    cwd         => "/nba-repo-${buildname}",
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
