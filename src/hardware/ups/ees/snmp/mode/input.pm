#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package hardware::ups::ees::snmp::mode::input;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'input', type => 0 }
    ];

    $self->{maps_counters}->{input} = [
        {
            label => 'line-a', nlabel => 'lineA.input.voltage.volt',
            set   => {
                key_values      => [ { name => 'lineA' } ],
                output_template => 'line A voltage: %.2fV',
                perfdatas       => [ { template => '%.2f', unit => 'V' } ]
            }
        },
        {
            label => 'line-b', nlabel => 'lineB.input.voltage.volt',
            set   => {
                key_values      => [ { name => 'lineB' } ],
                output_template => 'line B voltage: %.2fV',
                perfdatas       => [ { template => '%.2f', unit => 'V' } ]
            }
        },
        {
            label => 'line-c', nlabel => 'lineC.input.voltage.volt',
            set   => {
                key_values      => [ { name => 'lineC' } ],
                output_template => 'line C voltage: %.2fV',
                perfdatas       => [ { template => '%.2f', unit => 'V' } ]
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

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_psInputLineAVoltage = '.1.3.6.1.4.1.6302.2.1.2.6.1.0';
    my $oid_psInputLineBVoltage = '.1.3.6.1.4.1.6302.2.1.2.6.2.0';
    my $oid_psInputLineCVoltage = '.1.3.6.1.4.1.6302.2.1.2.6.3.0';

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [
            $oid_psInputLineAVoltage,
            $oid_psInputLineBVoltage,
            $oid_psInputLineCVoltage,
        ],
        nothing_quit => 1
    );

    $self->{input} = {
        lineA => $snmp_result->{$oid_psInputLineAVoltage} / 1000,
        lineB => $snmp_result->{$oid_psInputLineBVoltage} / 1000,
        lineC => $snmp_result->{$oid_psInputLineCVoltage} / 1000,
    };
}

1;

__END__

=head1 MODE

Check input lines.

=over 8

=item B<--warning-*> B<--critical-*>

Input thresholds in V

Thresholds: line-a, line-c, line-c.

=back

=cut
