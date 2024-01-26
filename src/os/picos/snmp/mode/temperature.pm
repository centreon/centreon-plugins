#
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

package os::picos::snmp::mode::temperature;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'switch-temperature', nlabel => 'switch.temperature.celsius', set => {
                key_values => [ { name => 'switch_temperature' } ],
                output_template => 'switch temperature: %s C',
                perfdatas => [
                    { template => '%s', unit => 'C' },
                ]
            }
        },
        { label => 'chip-temperature', nlabel => 'chip.temperature.celsius', set => {
                key_values => [ { name => 'chip_temperature' } ],
                output_template => 'Chip Temperature: %s C',
                perfdatas => [
                    { template => '%s', unit => 'C' },
                ],
            }
        },
        { label => 'cpu-temperature', nlabel => 'cpu.temperature.celsius', set => {
                key_values => [ { name => 'cpu_temperature' } ],
                output_template => 'CPU Temperature: %s C',
                perfdatas => [
                    { template => '%s', unit => 'C' },
                ],
            }
        }
    ];
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

    my $oid_switchTemperature = '.1.3.6.1.4.1.35098.1.5.0';
    my $oid_cpuTemperature = '.1.3.6.1.4.1.35098.1.6.0';
    my $oid_chipTemperature = '.1.3.6.1.4.1.35098.1.7.0';

    my $oids = [$oid_switchTemperature, $oid_chipTemperature, $oid_cpuTemperature];
    my $snmp_result = $options{snmp}->get_leef(
        oids => $oids,
        nothing_quit => 1
    );

    my $switch_temperature = $snmp_result->{$oid_switchTemperature} =~ s/\s\C.*//r;
    my $cpu_temperature = $snmp_result->{$oid_cpuTemperature} =~ s/\s\C.*//r;
    my $chip_temperature = $snmp_result->{$oid_chipTemperature} =~ s/\s\C.*//r;

    $self->{global} = {
        switch_temperature => $switch_temperature,
        cpu_temperature => $cpu_temperature,
        chip_temperature => $chip_temperature
    };
}

1;

__END__

=head1 MODE

Check temperature.

=over 8

=item B<--warning-switch-temperature>

Warning threshold in celsius degrees for Pica switch.

=item B<--critical-switch-temperature>

Critical threshold in celsius degrees for Pica switch.

=item B<--warning-chip-temperature>

Warning threshold in celsius degrees for chip.

=item B<--critical-chip-temperature>

Critical threshold in celsius degrees for chip.

=item B<--warning-cpu-temperature>

Warning threshold in celsius degrees for CPU.

=item B<--critical-cpu-temperature>

Critical threshold in celsius degrees for CPU.

=back

=cut
