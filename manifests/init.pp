# == Class: ipsilon
#
class ipsilon(
  $ipsilon_version     = 'master',
  $vhost_name          = $::fqdn,
  $serveradmin = "webmaster@${::fqdn}",
  $ipsilon_db_password,
  $ipsilon_db_hostname,
  $ipsilon_db_user     = 'ipsilon',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_chain_file = '',
) {

  $ipsilon_instance = 'idp'
  $ipsilon_uri = '/'
  $ipsilon_base = ''

  $ipsilon_base_dir = '/usr/local/share/ipsilon'
  $ipsilon_cache_dir = "/var/cache/ipsilon/$ipsilon_instance"
  $ipsilon_home_dir = "/var/lib/ipsilon/$ipsilon_instance"
  $ipsilon_session_dir = "$ipsilon_home_dir/sessions"
  $ipsilon_config_dir = "/etc/ipsilon/$ipsilon_instance"

  #libffi-dev
  $pip_packages = ['cherrypy', 'sqlalchemy', 'jinja2', 'PyMySQL', 'python-openid', 'bcrypt']
  $packages = ['libffi-dev', 'ssl-cert']

  include ::httpd
  include ::pip

  include ::httpd::mod::wsgi

  package { $packages:
    ensure => present,
  }

  package { $pip_packages:
    ensure => present,
    provider => pip,
    require  => Class['pip'],
  }


  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      require => Package['ssl-cert'],
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }


  vcsrepo { '/opt/ipsilon':
    ensure   => present,
    provider => git,
    revision => $ipsilon_version,
    source   => 'https://pagure.io/ipsilon',
  }

  file { '/opt/ipsilon/README':
    ensure    => '/opt/ipsilon/README.md',
    subscribe => Vcsrepo['/opt/ipsilon'],
  }

  exec { 'install_ipsilon' :
    command     => 'pip install /opt/ipsilon',
    path        => '/usr/local/bin:/usr/bin:/bin',
    refreshonly => true,
    subscribe   => File['/opt/ipsilon/README'],
    require     => User['ipsilon'],
  }
   
  group { 'ipsilon':
    ensure => present,
  }
	
  user { 'ipsilon':
    ensure => present,
    gid    => 'ipsilon',
  }

  file { '/etc/ipsilon':
    ensure => directory,
    owner  => 'root',
    group  => 'ipsilon',
    mode   => 0750,
  }

  file { "$ipsilon_config_dir":
    ensure => directory,
    owner  => 'root',
    group  => 'ipsilon',
    mode   => 0750,
  }

  file { "$ipsilon_config_dir/ipsilon.conf":
    owner => 'root',
    group => 'ipsilon',
    mode  => 0440,
    content => template('ipsilon/ipsilon.conf.erb'),
  }

  file { '/var/lib/ipsilon':
    ensure => directory,
  }

  file { "$ipsilon_home_dir":
    ensure => directory,
    owner  => 'ipsilon',
    group  => 'ipsilon',
    mode   => 0700,
  }

  file { "$ipsilon_home_dir/ipsilon.conf":
    ensure => "$ipsilon_config_dir/ipsilon.conf"
  }

  file { "$ipsilon_home_dir/public":
    ensure => directory,
    owner  => 'ipsilon',
    group  => 'ipsilon',
    mode   => 0700,
  }

  file { "$ipsilon_home_dir/public/well-known":
    ensure => directory,
    owner  => 'ipsilon',
    group  => 'ipsilon',
    mode   => 0700,
  }

  file { "$ipsilon_home_dir/sessions":
    ensure => directory,
    owner  => 'ipsilon',
    group  => 'ipsilon',
    mode   => 0700,
  }

  file { '/var/www/ipsilon':
    ensure => directory,
    mode   => 0755,
  }

  ::httpd::vhost { $vhost_name:
    port     => 443,
    priority => '50',
    docroot  => '/var/www/ipsilon',
    template => 'ipsilon/ipsilon.vhost.erb',
    ssl      => true,
  }

}

