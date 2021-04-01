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

package centreon::common::cisco::standard::snmp::mode::voicecall;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'gavg', type => 0, cb_prefix_output => 'prefix_gavg_output', message_separator => ' ', skipped_code => { -10 => 1 } },
        { name => 'ctype', type => 1, cb_prefix_output => 'prefix_ctype_output', message_multiple => 'All connection types are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{gavg} = [
        { label => 'active-1m-average', nlabel => 'calls.active.1m.average.count', set => {
                key_values => [ { name => 'active_1m_average' } ],
                output_template => '%.2f (1m)',
                perfdatas => [
                    { value => 'active_1m_average', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'active-5m-average', nlabel => 'calls.active.5m.average.count', set => {
                key_values => [ { name => 'active_5m_average' } ],
                output_template => '%.2f (5m)',
                perfdatas => [
                    { value => 'active_5m_average', template => '%.2f', min => 0 },
                ],
            }
        },
        { label => 'active-15m-average', nlabel => 'calls.active.15m.average.count', set => {
                key_values => [ { name => 'active_15m_average' } ],
                output_template => '%.2f (15m)',
                perfdatas => [
                    { value => 'active_15m_average', template => '%.2f', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{ctype} = [
        { label => 'connection-calls-active', nlabel => 'connection.calls.active.count', set => {
                key_values => [ { name => 'active_calls' }, { name => 'display' } ],
                output_template => 'active calls %s',
                perfdatas => [
                    { value => 'active_calls', template => '%s',
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_gavg_output {
    my ($self, %options) = @_;

    return 'Calls active ';
}

sub prefix_ctype_output {
    my ($self, %options) = @_;

    return "Connection type '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %map_con_type = (
        1 => 'h323', 2 => 'sip', 3 => 'mgcp',
        4 => 'sccp', 5 => 'multicast',
        6 => 'cacontrol', 7 => 'telephony',
    );
    my $oid_cvCallVolConnActiveConnection = '.1.3.6.1.4.1.9.9.63.1.3.8.1.1.2';
    my $oid_cvActiveCallStatsAvgVal_min = '.1.3.6.1.4.1.9.9.63.1.4.3.3.1.4.2';

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cvCallVolConnActiveConnection },
            { oid => $oid_cvActiveCallStatsAvgVal_min }
        ],
        nothing_quit => 1
    );

    $self->{ctype} = {};
    foreach (keys %{$snmp_result->{ $oid_cvCallVolConnActiveConnection }}) {
        /\.(\d+)$/;
        $self->{ctype}->{$map_con_type{$1}} = {
            display => $map_con_type{$1},
            active_calls => $snmp_result->{ $oid_cvCallVolConnActiveConnection }->{$_},
        };
    }

    my %definitions_avg = (
        'active_1m_average'  => [1, 1, 1, 0, 0],
        'active_5m_average'  => [1, 5, 5, 0, 0],
        'active_15m_average' => [1, 15, 15, 0, 0],
    );
    foreach my $oid (keys %{$snmp_result->{ $oid_cvActiveCallStatsAvgVal_min }}) {
        $oid =~ /\.(\d+)$/;
        my $interval = $1;
        foreach (values %definitions_avg) {            
            if ($interval >= $_->[0] && $interval <= $_->[1]) {
                $_->[3]++;
                $_->[4] += $snmp_result->{ $oid_cvActiveCallStatsAvgVal_min }->{$oid};
            }
        }
    }

    $self->{gavg} = {};
    foreach (keys %definitions_avg) {
        next if ($definitions_avg{$_}->[2] != $definitions_avg{$_}->[3]);
        $self->{gavg}->{$_} = $definitions_avg{$_}->[4] / $definitions_avg{$_}->[2];
    }
}

1;

__END__

=head1 MODE

Check call traffic statistics (CISCO-VOICE-DIAL-CONTROL-MIB)

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active-1m-average', 'active-5m-average', 'active-15m-average', 
'connection-calls-active'.

=back

=cut
