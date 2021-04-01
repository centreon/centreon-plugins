#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'upstatus' => 'network::fritzbox::mode::upstatus',
        'traffic'  => 'network::fritzbox::mode::traffic',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

This Plugin can check various things of your Fritz!Box.
Need perl-SOAP-Lite, you have to activate UPNP!

=cut
