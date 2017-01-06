#
#
#
class nba::docker::builder::etl(
  $git_checkout          = 'V2_master',
  $elasticsearch_version = '2.3.4',
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
  $image_name = "nba-etl-${buildname}"
  $docker_dir = "/docker-dir-${image_name}"
  $log_dir = "/var/log/docker-${image_name}"
  $repo_dir = "/nba-repo-${image_name}"
  $docker_builder = 'nba-etl-builder'
  ## BUILD STUFF
  file {[$docker_dir,$log_dir]:
    ensure => directory,
  }

  # file { "/payload-${buildname}/nba-config.py" :
  #   ensure => present,
  #   source => 'puppet:///modules/nba/nba-config.py',
  # }
  #
  # package { ['git']: }

  vcsrepo { $repo_dir :
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/naturalis/naturalis_data_api',
    revision => $git_checkout,
    require  => Package['git'],
    notify   => Exec["build etl-${buildname}"],
  }

  file {"${repo_dir}/nl.naturalis.nba.build/build.v2.properties" :
    content   => template('nba/build/docker_build.v2.properties.erb'),
    subscribe => Vcsrepo[$repo_dir],
    require   => Vcsrepo[$repo_dir],
  }

  # docker::run{'nba-es-buildsupport':
  #   image   => 'elasticsearch:2.3.5',
  #   ports   => ['9310:9300','9210:9200'],
  #   expose  => ['9300','9200'],
  #   tag     =>  $elasticsearch_version,
  #   env     => ['ES_JAVA_OPTS="-Xms512m -Xmx512m"'],
  #   command => 'elasticsearch -Des.cluster.name="buider-cluster"',
  #   require => Sysctl['vm.max_map_count'],
  # }

  docker::run{ $docker_builder :
    image   => 'openjdk:8',
    volumes => ["${repo_dir}:/code",
                  "${docker_dir}:/payload",
                  "${log_dir}:/var/log",
                  "${log_dir}:/code/nl.naturalis.nba.build/log"],
    command => '/bin/bash -c "/usr/bin/apt-get update;
                /usr/bin/apt-get -y install ant;
                cd /code/nl.naturalis.nba.build;
                ant install-etl-module"',
    running => false,
    detach  => false,
    require => File["${repo_dir}/nl.naturalis.nba.build/build.v2.properties"],
    # maybe pull on start to ensure latest image
  }

  file {"${docker_dir}/Dockerfile" :
    content => template('nba/docker/etl_Dockerfile.erb'),
    require => File[$docker_dir],
    notify  => Exec["build etl-${buildname}"],
  }


  exec {"build etl-${buildname}" :
    command     => "/usr/sbin/service docker-${docker_builder} start",
    refreshonly => true,
    require     => Docker::Run[$docker_builder],
    notify      => Exec["build docker image ${image_name}"]
  }

  exec {"build docker image ${image_name}" :
    command     => "/usr/bin/docker build --pull -t ${image_name}:${timestamp} ${docker_dir}",
    refreshonly => true,
    #onlyif      => "/usr/bin/test -f /payload-${buildname}/nba.war",
    require     => File["${docker_dir}/Dockerfile"],
    notify      => [Exec["tag repo with ${image_name}:${timestamp}"],
                    Exec["tag repo with ${image_name}:latest"]],
  }

  exec {"cleanup elt-${buildname} build files" :
    command     => "/bin/rm -fr ${docker_dir}/*",
    refreshonly => true,
    notify      => Exec["cleanup ${repo_dir}"],
  }

  exec {"cleanup ${repo_dir}" :
    command     => "/usr/bin/git checkout ${git_checkout} ; /usr/bin/git reset --hard",
    cwd         => $repo_dir,
    refreshonly => true,
  }

  exec {"tag repo with ${image_name}:${timestamp}" :
    command     => "/usr/bin/docker tag ${image_name}:${timestamp} localhost:5000/${image_name}:${timestamp}",
    refreshonly => true,
    notify      => Exec["push image ${image_name}:${timestamp}"],
  }

  exec {"tag repo with ${image_name}:latest" :
    command     => "/usr/bin/docker tag ${image_name}:${timestamp} localhost:5000/${image_name}:latest",
    refreshonly => true,
    notify      => Exec["push image ${image_name}:latest"],
  }

  exec {"push image ${image_name}:${timestamp}" :
    command     => "/usr/bin/docker push localhost:5000/${image_name}:${timestamp}",
    refreshonly => true,
    notify      => Exec["cleanup local docker image ${image_name}"],
  }

  exec {"push image ${image_name}:latest" :
    command     => "/usr/bin/docker push localhost:5000/${image_name}:latest",
    refreshonly => true,
    notify      => Exec["cleanup local docker image ${image_name}"],
  }

  exec {"cleanup local docker image ${image_name}" :
    command     => "/usr/bin/docker rmi ${image_name}:${timestamp}",
    refreshonly => true,
  }


  # docker::run{'nba-v2-wildfly':
  #   image   => 'nba-v2-wildfly-image',
  #   tag     => '',
  #   depends => 'nba-builder',
  #   running => false,
  #   require => Docker::Image['nba-v2-wildfly-image']
  # }


}
