define nba::lb::wwwfiles(
  $template = '',
  $type    = 'file'
)
{
   case $type {
     'file' : {
       if ($template == '') {
         fail 'Template should have a reasonable value'
       }
       file { $title :
         ensure  => present,
         content => template($template),
       }
     }
     'dir' : {
       file { $title :
         ensure => directory,
       }
     }
     default: {
       fail 'Type should be "file" or "dir"'
     }
   }
}
