# == Definition: network::bond
#
# Creates a bond interface with no IP information and enables the bonding
# driver.
#
# === Parameters:
#
#   $ensure       - required - up|down
#   $mtu          - optional
#   $ethtool_opts - optional
#   $bonding_opts - optional
#
# === Actions:
#
# Deploys the file /etc/sysconfig/network-scripts/ifcfg-$name.
# Updates /etc/modprobe.conf with bonding driver parameters.
#
# === Sample Usage:
#
#   network::bond { 'bond0':
#     ensure       => 'up',
#     bonding_opts => 'mode=active-backup miimon=100',
#   }
#
# === Authors:
#
# Martin Millnert <martin@millnert.se>
# Based on bond/static.pp, by Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2015 Martin Millnert
# Copyright (C) 2011 Mike Arnold

define network::bond (
  $ensure,
  $mtu = undef,
  $ethtool_opts = undef,
  $bonding_opts = 'miimon=100',
) {
  # Validate our regular expressions
  $states = [ '^up$', '^down$' ]
  validate_re($ensure, $states, '$ensure must be either "up" or "down".')

  network_if_base { $title:
    ensure       => $ensure,
    ipaddress    => undef,
    netmask      => undef,
    gateway      => undef,
    macaddress   => undef,
    bootproto    => 'none',
    mtu          => $mtu,
    ethtool_opts => $ethtool_opts,
    bonding_opts => $bonding_opts,
    peerdns      => undef,
    ipv6init     => undef,
    ipv6address  => undef,
    ipv6peerdns  => undef,
    ipv6gateway  => undef,
    dns1         => undef,
    dns2         => undef,
    domain       => undef,
  }

  # Only install "alias bondN bonding" on old OSs that support
  # /etc/modprobe.conf.
  case $::operatingsystem {
    /^(RedHat|CentOS|OEL|OracleLinux|SLC|Scientific)$/: {
      case $::operatingsystemrelease {
        /^[45]/: {
          augeas { "modprobe.conf_${title}":
            context => '/files/etc/modprobe.conf',
            changes => [
              "set alias[last()+1] ${title}",
              'set alias[last()]/modulename bonding',
            ],
            onlyif  => "match alias[*][. = '${title}'] size == 0",
            before  => Network_if_base[$title],
          }
        }
        default: {}
      }
    }
    'Fedora': {
      case $::operatingsystemrelease {
        /^(1|2|3|4|5|6|7|8|9|10|11)$/: {
          augeas { "modprobe.conf_${title}":
            context => '/files/etc/modprobe.conf',
            changes => [
              "set alias[last()+1] ${title}",
              'set alias[last()]/modulename bonding',
            ],
            onlyif  => "match alias[*][. = '${title}'] size == 0",
            before  => Network_if_base[$title],
          }
        }
        default: {}
      }
    }
    default: {}
  }
} # define network::bond
