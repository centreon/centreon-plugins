#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::common::cisco::standard::snmp::mode::vpc;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_keepalive_status = (
    1 => 'disabled',
    2 => 'alive',
    3 => 'peerUnreachable',
    4 => 'aliveButDomainIdDismatch',
    5 => 'suspendedAsISSU',
    6 => 'suspendedAsDestIPUnreachable',
    7 => 'suspendedAsVRFUnusable',
    8 => 'misconfigured'
);
my %map_role_status = (
    1 => 'primarySecondary',
    2 => 'primary',
    3 => 'secondaryPrimary',
    4 => 'secondary',
    5 => 'noneEstablished'
);
my %map_link_status = (
    1 => 'down',
    2 => 'downStar',
    3 => 'up'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    # $options{options}->add_options(arguments => {
    #     'role:s'        => { name => 'role', default => 'primary' },
    # });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    my $oid_cVpcRoleState = ".1.3.6.1.4.1.9.9.807.1.2.1.1.2";    # VPC Role Status
    my $oid_cVpcStatusHostLinkStatus = ".1.3.6.1.4.1.9.9.807.1.4.2.1.4";   # HostLink Status
    my $oid_cVpcPeerKeepAliveStatus = ".1.3.6.1.4.1.9.9.807.1.1.2.1.2"; # Peer Keepalive Status

    my $results = $self->{snmp}->get_multiple_table(oids => 
        [
            { oid => $oid_cVpcRoleState },
            { oid => $oid_cVpcStatusHostLinkStatus },
            { oid => $oid_cVpcPeerKeepAliveStatus },
        ],
        nothing_quit => 1
    );

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("VPC Peer Established and Connected"));

    my ($roleState,$linkState,$keepAliveState);

    foreach my $oid (keys %{$results->{$oid_cVpcRoleState}}) {
        $roleState = $results->{$oid_cVpcRoleState}->{$oid};
    }
    foreach my $oid (keys %{$results->{$oid_cVpcStatusHostLinkStatus}}) {
        $linkState = $results->{$oid_cVpcStatusHostLinkStatus}->{$oid};
    }
    foreach my $oid (keys %{$results->{$oid_cVpcPeerKeepAliveStatus}}) {
        $keepAliveState = $results->{$oid_cVpcPeerKeepAliveStatus}->{$oid};
    }

    $self->{output}->output_add(short_msg => sprintf("[Role Status is '%s'] [Peer Established Status is '%s'] [KeepAlive Status is '%s']",
                                                    $map_role_status{$roleState}, $map_link_status{$linkState}, $map_keepalive_status{$keepAliveState}));
    
    if ($map_link_status{$linkState} =~ /^downStar$/i) {
        $self->{output}->output_add(severity => 'WARNING',
    			                    short_msg => sprintf("Local Link is Down, Forwarding via peer link"));
    }
    
    if ($map_link_status{$linkState} =~ /^down$/i) {
        $self->{output}->output_add(severity => 'CRITICAL',
    			                    short_msg => sprintf("Peer Link is '%s'", $map_link_status{$linkState}));
    }

    if ($map_keepalive_status{$keepAliveState} !~ /^alive$/i) {
        $self->{output}->output_add(severity => 'CRITICAL',
    			                    short_msg => sprintf("Keep Alive state is '%s'", $map_keepalive_status{$keepAliveState}));
    }

    if ($map_role_status{$roleState} !~ /^primarySecondary|secondaryPrimary$/i) {
        if ($map_role_status{$roleState} =~ /^primary|secondary$/i) {
            $self->{output}->output_add(severity => 'WARNING',
    			                        short_msg => sprintf("Check Switch Role State - Currently '%s'", $map_role_status{$roleState}));
        }
        else {
            $self->{output}->output_add(severity => 'CRITICAL',
    			                        short_msg => sprintf("Switch role state is '%s'", $map_role_status{$roleState}));
        }
    }   

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Cisco VPC (CISCO-VPC-MIB). Trigger a critical if not in the expected role state, or if the Peer Link state is down, or if the KeepAlive state is anything other than alive.

=over 8

=back

=cut
    
