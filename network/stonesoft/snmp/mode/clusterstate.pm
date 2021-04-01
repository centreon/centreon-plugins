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

package network::stonesoft::snmp::mode::clusterstate;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Node status is '%s' [Member id: %s]",
        $self->{result_values}->{node_status},
        $self->{result_values}->{node_member_id}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

     $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{node_status} =~ /unknown/i',
            warning_default => '%{node_status} =~ /lockedOnline/i',
            critical_default => '%{node_status} =~ /^(?:offline|goingOffline|lockedOffline|goingLockedOffline|standby|goingStandby)$/i',
            set => {
                key_values => [ { name => 'node_status' }, { name => 'node_member_id' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ]
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_oper_state = {
    0 => 'unknown',
    1 => 'online',
    2 => 'goingOnline',
    3 => 'lockedOnline',
    4 => 'goingLockedOnline',
    5 => 'offline',
    6 => 'goingOffline',
    7 => 'lockedOffline',
    8 => 'goingLockedOffline',
    9 => 'standby',
    10 => 'goingStandby'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_nodeMemberId = '.1.3.6.1.4.1.1369.6.1.1.2.0';
    my $oid_nodeOperState = '.1.3.6.1.4.1.1369.6.1.1.3.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_nodeMemberId, $oid_nodeOperState], nothing_quit => 1);
    $self->{global} = {
        node_status => $map_oper_state->{ $snmp_result->{$oid_nodeOperState} },
        node_member_id => $snmp_result->{$oid_nodeMemberId}
    };
}

1;

__END__

=head1 MODE

Check status of clustered node.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{node_status} =~ /unknown/i').
Can used special variables like: %{node_status}, %{node_member_id}.

=item B<--warning-status>

Set warning threshold for status (Default: '%{node_status} =~ /lockedOnline/i').
Can used special variables like: %{node_status}, %{node_member_id}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{node_status} =~ /^(?:offline|goingOffline|lockedOffline|goingLockedOffline|standby|goingStandby)$/i').
Can used special variables like: %{node_status}, %{node_member_id}.

=back

=cut
    
