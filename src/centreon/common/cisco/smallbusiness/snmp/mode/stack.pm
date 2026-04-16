# Copyright 2024 Centreon (http://www.centreon.com/)
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

package centreon::common::cisco::smallbusiness::snmp::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_connection_status_output {
    my ($self, %options) = @_;

    my $msg = "is notConnected";
    if ($self->{result_values}->{connectionStatus} eq 'connected') {
       $msg = "is connected to unit '" . $self->{result_values}->{connectedMemberUnit} . "'";
    }
    return $msg;
}

sub prefix_connection_output {
    my ($self, %options) = @_;

    return sprintf(
        "'%s' side connection ",
        $options{instance_value}->{connectionSide}
    );
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return sprintf(
        "stack member '%s' [unit: %s] ",
        $options{instance_value}->{macAddr},
        $options{instance_value}->{memberUnit}
    );
}

sub member_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking stack member '%s' [unit: %s]",
        $options{instance_value}->{macAddr},
        $options{instance_value}->{memberUnit}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'members', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All stack members are ok',
          group => [
                { name => 'member_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'connections', type => 1, cb_prefix_output => 'prefix_connection_output', message_multiple => 'All connections are ok' }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'members-detected', nlabel => 'stack.members.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'Number of members detected: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{member_global} = [
        { label => 'member-connected-members', nlabel => 'stack.member.connected.members.count', set => {
                key_values => [ { name => 'connected' } ],
                output_template => 'number of connected members: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{connections} = [
        { label => 'member-connection-status', type => 2, set => {
                key_values => [ { name => 'connectionStatus' }, { name => 'connectionSide' }, { name => 'connectedMemberUnit' } ],
                closure_custom_output => $self->can('custom_connection_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my $mapping = {
    rlPhdStackConnect1 => { oid => '.1.3.6.1.4.1.9.6.1.101.53.4.1.3' },
    rlPhdStackConnect2 => { oid => '.1.3.6.1.4.1.9.6.1.101.53.4.1.4' },
    rlPhdStackMacAddr  => { oid => '.1.3.6.1.4.1.9.6.1.101.53.4.1.7' }
};
my $oid_rlPhdStackEntry = '.1.3.6.1.4.1.9.6.1.101.53.4.1';

sub manage_selection {
    my ($self, %options) = @_;


    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_rlPhdStackEntry,
        start => $mapping->{rlPhdStackConnect1}->{oid},
        nothing_quit => 1
    );

    $self->{global} = { detected => 0 };
    $self->{members} = {};
    foreach my $oid (keys %$snmp_result) {
        next if($oid !~ /^$mapping->{rlPhdStackMacAddr}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{members}->{$instance} = {
            memberUnit => $instance,
            macAddr => join(':', unpack('(H2)*', $result->{rlPhdStackMacAddr})),
            member_global => {
                connected => 0
            },
            connections => {
                1 => {
                    connectionSide => 'left',
                    connectionStatus => $result->{rlPhdStackConnect1} > 0 ? 'connected' : 'notConnected',
                    connectedMemberUnit => $result->{rlPhdStackConnect1}
                },
                2 => {
                    connectionSide => 'right',
                    connectionStatus => $result->{rlPhdStackConnect2} > 0 ? 'connected' : 'notConnected',
                    connectedMemberUnit => $result->{rlPhdStackConnect2}
                }
            }
        };

        $self->{members}->{$instance}->{member_global}->{connected}++ if ($result->{rlPhdStackConnect1} > 0);
        $self->{members}->{$instance}->{member_global}->{connected}++ if ($result->{rlPhdStackConnect2} > 0);

        $self->{global}->{detected}++;
    }
}

1;

=head1 MODE

Check stack.

=over 8

=item B<--warning-member-connection-status>

Set warning threshold for member connection status.
You can use the following variables: %{connectionStatus}, %{connectionSide}, %{connectedMemberUnit}

=item B<--critical-member-connection-status>

Set critical threshold for member connection status.
You can use the following variables: %{connectionStatus}, %{connectionSide}, %{connectedMemberUnit}

=item B<--warning-members-detected>

Thresholds.

=item B<--critical-members-detected>

Thresholds.

=item B<--warning-member-connected-members>

Thresholds.

=item B<--critical-member-connected-members>

Thresholds.

=back

=cut

