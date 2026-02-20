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

package network::kairos::snmp::mode::hardware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use centreon::plugins::constants qw(:counters);

sub prefix_board_output {
    my ($self, %options) = @_;

    return 'Board ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'board', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_board_output' }
    ];

    $self->{maps_counters}->{board} = [
        {
            label => 'board-voltage', nlabel => 'board.voltage.volt',
            set   => {
                key_values      => [ { name => 'inputVoltage' } ],
                output_template => 'voltage: %.2fV',
                perfdatas       => [ { template => '%.2f', unit => 'V' } ]
            }
        },
        {
            label => 'board-tx-current', nlabel => 'board.tx.current.ampere',
            set   => {
                key_values      => [ { name => 'txCurrent' } ],
                output_template => 'TX current: %.2fA',
                perfdatas       => [ { template => '%.2f', unit => 'A' } ]
            }
        },
        { label => 'board-temperature', nlabel => 'board.temperature.celsius', 
            set => {
                key_values => [ { name => 'boardTemp' } ],
                output_template => 'temperature is %s C',
                perfdatas => [
                    { template => '%s', unit => 'C' }
                ]
            }
        },
        { label => 'board-tx-temperature', nlabel => 'board.tx.temperature.celsius', 
            set => {
                key_values => [ { name => 'txTemp' } ],
                output_template => 'TX temperature is %s C',
                perfdatas => [
                    { template => '%s', unit => 'C' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_kairosHndMainStatusInputVoltage = '.1.3.6.1.4.1.37755.61.2.1.1.0';
    my $oid_kairosHndMainStatusBoardTemp = '.1.3.6.1.4.1.37755.61.2.1.2.0';
    my $oid_kairosHndMainStatusTxTemp = '.1.3.6.1.4.1.37755.61.2.1.3.0';
    my $oid_kairosHndMainStatusTxCurrent = '.1.3.6.1.4.1.37755.61.2.1.4.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [
            $oid_kairosHndMainStatusInputVoltage,
            $oid_kairosHndMainStatusBoardTemp,
            $oid_kairosHndMainStatusTxTemp,
            $oid_kairosHndMainStatusTxCurrent
        ],
        nothing_quit => 1
    );

    $self->{board} = {
        inputVoltage => $snmp_result->{$oid_kairosHndMainStatusInputVoltage},
        txCurrent    => $snmp_result->{$oid_kairosHndMainStatusTxCurrent},
        boardTemp    => $snmp_result->{$oid_kairosHndMainStatusBoardTemp},
        txTemp       => $snmp_result->{$oid_kairosHndMainStatusTxTemp}
    };
}

1;

__END__

=head1 MODE

Check hardware sensors.

=over 8

=item B<--warning-board-temperature>

Threshold in C.

=item B<--critical-board-temperature>

Threshold in C.

=item B<--warning-board-tx-current>

Threshold in Amperes.

=item B<--critical-board-tx-current>

Threshold in Amperes.

=item B<--warning-board-tx-temperature>

Threshold in C.

=item B<--critical-board-tx-temperature>

Threshold in C.

=item B<--warning-board-voltage>

Threshold in Volts.

=item B<--critical-board-voltage>

Threshold in Volts.

=back

=cut
