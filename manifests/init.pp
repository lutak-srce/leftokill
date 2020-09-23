#
# = Class: leftokill
#
# This class manages leftokill service
#
#
# == Parameters
#
# [*ensure*]
#   Type: string, default: 'present'
#   Manages package installation and class resources. Possible values:
#   * 'present' - Install package, ensure files are present (default)
#   * 'absent'  - Stop service and remove package and managed files
#
# [*package*]
#   Type: string, default on $::osfamily basis
#   Manages the name of the package.
#
# [*version*]
#   Type: string, default: undef
#   If this value is set, the defined version of package is installed.
#   Possible values are:
#   * 'x.y.z' - Specific version
#   * latest  - Latest available
#
# [*service*]
#   Type: string, defaults on $::osfamily basis
#   Name of the service. Defaults are provided on
#   $::osfamily basis.
#
# [*status*]
#   Type: string, default: 'enabled'
#   Define the provided service status. Available values affect both the
#   ensure and the enable service arguments:
#   * 'enabled':     ensure => running, enable => true
#   * 'disabled':    ensure => stopped, enable => false
#   * 'running':     ensure => running, enable => undef
#   * 'stopped':     ensure => stopped, enable => undef
#   * 'activated':   ensure => undef  , enable => true
#   * 'deactivated': ensure => undef  , enable => false
#   * 'unmanaged':   ensure => undef  , enable => undef
#
# [*file_mode*]
# [*file_owner*]
# [*file_group*]
#   Type: string, default: '0600'
#   Type: string, default: 'root'
#   Type: string, default 'root'
#   File permissions and ownership information assigned to config files.
#
# [*dependency_class*]
#   Type: string, default: leftokill::dependency
#   Name of a class that contains resources needed by this module but provided
#   by external modules. Set to undef to not include any dependency class.
#
# [*my_class*]
#   Type: string, default: undef
#   Name of a custom class to autoload to manage module's customizations
#
# [*noops*]
#   Type: boolean, default: undef
#   Set noop metaparameter to true for all the resources managed by the module.
#   If true no real change is done is done by the module on the system.
#
class leftokill (
  $ensure            = $::leftokill::params::ensure,
  $package           = $::leftokill::params::package,
  $version           = $::leftokill::params::version,
  $service           = $::leftokill::params::service,
  $status            = $::leftokill::params::status,
  $file_mode         = $::leftokill::params::file_mode,
  $file_owner        = $::leftokill::params::file_owner,
  $file_group        = $::leftokill::params::file_group,
  $dependency_class  = $::leftokill::params::dependency_class,
  $my_class          = $::leftokill::params::my_class,
  $noops             = undef,

  $config_file       = $::leftokill::params::config_file,
  $conf_template     = $::leftokill::params::conf_template,
  $general           = {},
  $report            = {},
) inherits leftokill::params {

  ### Input parameters validation
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent')
  validate_string($package)
  validate_string($version)
  validate_string($service)
  validate_re($status,  ['enabled','disabled','running','stopped','activated','deactivated','unmanaged'], 'Valid values are: enabled, disabled, running, stopped, activated, deactivated and unmanaged')

  validate_string($config_file)
  validate_string($conf_template)
  validate_hash($general)
  validate_hash($report)

  ### Internal variables (that map class parameters)
  if $ensure == 'present' {
    $package_ensure = $version ? {
      ''      => 'present',
      default => $version,
    }
    $service_enable = $status ? {
      'enabled'     => true,
      'disabled'    => false,
      'running'     => undef,
      'stopped'     => undef,
      'activated'   => true,
      'deactivated' => false,
      'unmanaged'   => undef,
    }
    $service_ensure = $status ? {
      'enabled'     => 'running',
      'disabled'    => 'stopped',
      'running'     => 'running',
      'stopped'     => 'stopped',
      'activated'   => undef,
      'deactivated' => undef,
      'unmanaged'   => undef,
    }
    $file_ensure = present
  } else {
    $package_ensure = 'absent'
    $service_enable = undef
    $service_ensure = stopped
    $file_ensure    = absent
  }

  # set defaults for file resource in this scope.
  File {
    ensure  => $file_ensure,
    owner   => $file_owner,
    group   => $file_group,
    mode    => $file_mode,
    noop    => $noops,
  }

  ### Extra classes
  if $dependency_class { include $dependency_class }
  if $my_class         { include $my_class         }

  $general_section = merge($::leftokill::params::general, $::leftokill::general)
  $report_section = merge($::leftokill::params::report, $::leftokill::report)

  file { $config_file:
    content => template($conf_template),
    notify  => Service['leftokill'],
    require => Package['leftokill'],
  }

  package { 'leftokill':
    ensure => $package_ensure,
    name   => $package,
    noop   => $noops,
  }

  service { 'leftokill':
    ensure  => $service_ensure,
    enable  => $service_enable,
    require => File[$config_file],
    noop    => $noops,
  }

}
# vi:syntax=puppet:filetype=puppet:ts=4:et:nowrap:
