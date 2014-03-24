################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Florian Asche <info@florian-asche.de>
#
####################################################################################

####################################################################################
#
# Mode Tested with Fritz!Box 6360
#
####################################################################################

####################################################################################
# DOCUMENTATION
####################################################################################

###GetAddonInfos
#NewVoipDNSServer1                  : 0.0.0.0
#NewDNSServer2                      : 10.10.133.78
#NewDNSServer1                      : 10.10.133.78
#NewVoipDNSServer2                  : 0.0.0.0
#NewIdleDisconnectTime              : 0
#NewByteSendRate                    : 1560
#NewAutoDisconnectTime              : 0
#NewTotalBytesSent                  : 411607957
#NewByteReceiveRate                 : 5073
#NewPacketReceiveRate               : 31
#NewRoutedBridgedModeBoth           : 0
#NewTotalBytesReceived              : 4186731846
#NewPacketSendRate                  : 17
#NewUpnpControlEnabled              : 0

###GetCommonLinkProperties
#NewPhysicalLinkStatus              : Up
#NewLayer1DownstreamMaxBitRate      : 112640000
#NewWANAccessType                   : DSL
#NewLayer1UpstreamMaxBitRate        : 5248000

###GetStatusInfo
#NewConnectionStatus                : Connected
#NewLastConnectionError             : ERROR_NONE
#NewUptime                          : 903867

###GetExternalIPAddress
#NewExternalIPAddress               : 133.71.33.7
####################################################################################

package network::fritzbox::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);
use SOAP::Lite;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'upstatus'     => 'network::fritzbox::mode::upstatus',
                         'traffic'      => 'network::fritzbox::mode::traffic',
                        );
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

This Plugin can check various things of your Fritz!Box.
Need perl-SOAP-Lite, you have to activate UPNP!

=cut
