#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global',  type => COUNTER_TYPE_GLOBAL },
        { name => 'policy',  type => COUNTER_TYPE_INSTANCE },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'udp', set => {
                key_values => [ { name => 'udp' } ],
                output_template => 'UDP : %d connections',
                perfdatas => [
                    { label => 'udp', template => '%d', min => 0, unit => 'con' }
                ]
            }
        },
        { label => 'tcp', set => {
                key_values => [ { name => 'tcp' } ],
                output_template => 'TCP : %d connections',
                perfdatas => [
                    { label => 'tcp', template => '%d', min => 0, unit => 'con' }
                ]
            }
        },
        { label => 'major', set => {
                key_values => [ { name => 'major' } ],
                output_template => 'Major Alarms : %d',
                perfdatas => [
                    { label => 'major', template => '%d', min => 0, unit => 'alarms' }
                ]
            }
        },
        { label => 'minor', set => {
                key_values => [ { name => 'minor' } ],
                output_template => 'Minor Alarms : %d',
                perfdatas => [
                    { label => 'minor', template => '%d', min => 0, unit => 'alarms' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{policy} = [
        { label => 'policy-dummy', threshold => 0, set => {
                key_values => [ { name => 'index' }, { name => 'name' }, { name => 'slot_name' },
                                { name => 'active' }, { name => 'sync' } ],
                closure_custom_output => $self->can('custom_policy_output'),
                perfdatas => []
            }
        }
    ];
}

sub custom_policy_output {
    my ($self, %options) = @_;
    my $obj = $options{new_datas};
    return sprintf(
        "Policy: '%s', slot: '%s', active: '%s', sync: %s",
        $self->{result_values}->{name},
        $self->{result_values}->{slot_name},
        $self->{result_values}->{active},
        $self->{result_values}->{sync} ? 'True' : 'False'
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_snsASQStatsStatefulUdpConn    = '.1.3.6.1.4.1.11256.1.12.1.33.0';
    my $oid_snsASQStatsStatefulTcpConn    = '.1.3.6.1.4.1.11256.1.12.1.23.0';
    my $oid_snsASQStatsStatefulMajorAlarm = '.1.3.6.1.4.1.11256.1.12.1.12.0';
    my $oid_snsASQStatsStatefulMinorAlarm = '.1.3.6.1.4.1.11256.1.12.1.11.0';

    my $result_asq = $options{snmp}->get_leef(
        oids        => [ $oid_snsASQStatsStatefulUdpConn, $oid_snsASQStatsStatefulTcpConn, $oid_snsASQStatsStatefulMajorAlarm, $oid_snsASQStatsStatefulMinorAlarm ],
        nothing_quit => 1
    );

    $self->{global} = {
        udp   => $result_asq->{$oid_snsASQStatsStatefulUdpConn},
        tcp   => $result_asq->{$oid_snsASQStatsStatefulTcpConn},
        major => $result_asq->{$oid_snsASQStatsStatefulMajorAlarm},
        minor => $result_asq->{$oid_snsASQStatsStatefulMinorAlarm}
    };
    

    my $oid_snsPolicyIndex    = '.1.3.6.1.4.1.11256.1.8.1.1.1';
    my $oid_snsPolicyName     = '.1.3.6.1.4.1.11256.1.8.1.1.2';
    my $oid_snsPolicySlotName = '.1.3.6.1.4.1.11256.1.8.1.1.3';
    my $oid_snsPolicyActive   = '.1.3.6.1.4.1.11256.1.8.1.1.4';
    my $oid_snsPolicySync     = '.1.3.6.1.4.1.11256.1.8.1.1.5';

    my $result_policy = $options{snmp}->get_table(
        oid          => '.1.3.6.1.4.1.11256.1.8.1.1',
        nothing_quit => 1
    );

    $self->{policy} = {};
    foreach my $oid (keys %{$result_policy}) {
        next unless $oid =~ /^$oid_snsPolicyIndex\.(\d+)$/;
        my $idx = $1;
        $self->{policy}->{$idx} = {
            index     => $idx,
            name      => $result_policy->{"$oid_snsPolicyName.$idx"}     // '',
            slot_name => $result_policy->{"$oid_snsPolicySlotName.$idx"} // '',
            active    => $result_policy->{"$oid_snsPolicyActive.$idx"}   // '',
            sync      => $result_policy->{"$oid_snsPolicySync.$idx"}     // 0,
        };
    }
}

1;

__END__

=head1 MODE

Check connections setup rate and policy table on Stormshield Firewall equipments.

=over 8

=item B<--warning-tcp>

Warning threshold for TCP connections.

=item B<--warning-udp>

Warning threshold for UDP connections.

=item B<--warning-major>

Warning threshold for Major Alarms.

=item B<--warning-minor>

Warning threshold for Minor Alarms.

=item B<--critical-tcp>

Critical threshold for TCP connections.

=item B<--critical-udp>

Critical threshold for UDP connections.

=item B<--critical-major>

Critical threshold for Major Alarms.

=item B<--critical-minor>

Critical threshold for Minor Alarms.

=back

=cut