# == Class owncloud::apache
#
# This class is called from owncloud.
#
class owncloud::apache {

  if $::owncloud::manage_apache {
    class { '::apache':
      default_vhost => false,
      mpm_module    => 'prefork',
      purge_configs => false,
      server_tokens => 'prod',
    }

    include '::apache::mod::php', '::apache::mod::rewrite', '::apache::mod::ssl'
  }

  if $::owncloud::manage_vhost {
    $vhost_directories_common = {
        path            => $::owncloud::documentroot,
        options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
        allow_override  => 'All',
        custom_fragment => 'Dav Off',
      }

    if $::owncloud::apache_version == '2.2' {
      $vhost_directories_version = {
        order   => 'allow,deny',
        allow   => 'from All',
        satisfy => 'Any',
      }
    } else {
      $vhost_directories_version = {
        require => 'all granted'
      }
    }

    $vhost_directories = merge($vhost_directories_common, $vhost_directories_version)

    if $::owncloud::ssl {
      apache::vhost { 'owncloud-http':
        servername => $::owncloud::url,
        port       => $::owncloud::http_port,
        docroot    => $::owncloud::documentroot,
        rewrites   => [
          {
            comment      => 'redirect non-SSL traffic to SSL site',
            rewrite_cond => ['%{HTTPS} off'],
            rewrite_rule => ['(.*) https://%{HTTP_HOST}%{REQUEST_URI}'],
          }
        ]
      }

      apache::vhost { 'owncloud-https':
        servername  => $::owncloud::url,
        port        => $::owncloud::https_port,
        docroot     => $::owncloud::documentroot,
        directories => $vhost_directories,
        headers     => "add Strict-Transport-Security \"max-age=15768000\"",
        ssl         => true,
        ssl_ca      => $::owncloud::ssl_ca,
        ssl_cert    => $::owncloud::ssl_cert,
        ssl_chain   => $::owncloud::ssl_chain,
        ssl_key     => $::owncloud::ssl_key,
        ssl_cipher  => $::owncloud::ssl_cipher,
      }
    } else {
      apache::vhost { 'owncloud-http':
        servername  => $::owncloud::url,
        port        => $::owncloud::http_port,
        docroot     => $::owncloud::documentroot,
        directories => $vhost_directories,
      }
    }
  }
}
