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

package hardware::pdu::epdu::snmp::mode::phases;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub prefix_phase_output {
    my ($self, %options) = @_;

    return "Phase '" . $options{instance} . "' current ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'phase',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_phase_output',
            message_multiple => 'All current phases are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{phase} = [
        { label => 'voltage', nlabel => 'phase.voltage.volt', display_ok => 0, set => {
            key_values      => [ { name => 'voltage' }, { name => 'display' } ],
            output_template => 'Voltage : %.2f V',
            perfdatas       => [
                {
                    template             => '%s',
                    unit                 => 'V',
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ],
        }
        },
        { label => 'current', nlabel => 'phase.current.ampere', display_ok => 0, set => {
            key_values      => [ { name => 'current' }, { name => 'display' } ],
            output_template => 'Current : %.2f A',
            perfdatas       => [
                {
                    template             => '%s',
                    unit                 => 'A',
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ],
        }
        },
        { label => 'active-power', nlabel => 'phase.active.power.watt', display_ok => 1, set => {
            key_values      => [ { name => 'active_power' }, { name => 'display' } ],
            output_template => 'active power: %s W',
            perfdatas       => [
                {
                    template             => '%d',
                    unit                 => 'W',
                    min                  => 0,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ]
        }
        },
        { label => 'reactive-power', nlabel => 'phase.reactive.power.reactive.voltampere', display_ok => 0,
            set => {
                key_values      => [ { name => 'reactive_power' }, { name => 'display' } ],
                output_template => 'reactive power: %s Var',
                perfdatas       => [
                    {
                        template             => '%s',
                        unit                 => 'Var',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
            }
        },
        { label => 'apparent-power', nlabel => 'phase.apparent.power.voltampere', display_ok => 0, set => {
            key_values      => [ { name => 'apparent_power' }, { name => 'display' } ],
            output_template => 'apparent power: %s VA',
            perfdatas       => [
                {
                    template             => '%s',
                    unit                 => 'VA',
                    min                  => 0,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ]
        }
        },
        { label => 'energy', nlabel => 'phase.energy.kilowatthour', display_ok => 0, set => {
            key_values      => [ { name => 'energy' }, { name => 'display' } ],
            output_template => 'Total energy : %.3f kWh', output_error_template => "Total energy : %s",
            perfdatas       => [
                {
                    template             => '%.3f',
                    unit                 => 'kWh',
                    min                  => 0,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                },
            ],
        }
        },
        { label => 'power-factor', nlabel => 'phase.power.factor.percent', display_ok => 1, set => {
            key_values      => [ { name => 'power_factor' }, { name => 'display' } ],
            output_template => 'Power factor : %.2f %%',
            perfdatas       => [
                {
                    template             => '%s',
                    unit                 => '%',
                    min                  => 0,
                    max                  => 100,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ],
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            'include-phase:s' => { name => 'include_phase' },
            'exclude-phase:s' => { name => 'exclude_phase' }
        });

    return $self;
}

my $mapping = {
    ePDUPhaseStatusModule        => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.2' },
    ePDUPhaseStatusNumber        => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.3' },
    ePDUPhaseStatusVoltage       => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.4' },
    ePDUPhaseStatusCurrent       => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.5' },
    ePDUPhaseStatusActivePower   => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.6' },
    ePDUPhaseStatusReactivePower => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.7' },
    ePDUPhaseStatusApparentPower => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.8' },
    ePDUPhaseStatusPowerFactor   => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.9' },
    ePDUPhaseStatusEnergy        => { oid => '.1.3.6.1.4.1.318.1.1.30.4.2.1.10' }
};

my $oid_ePDUPhaseStatusEntry = '.1.3.6.1.4.1.318.1.1.30.4.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_ePDUPhaseStatusEntry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ePDUPhaseStatusModule}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);

        my $instance = $result->{ePDUPhaseStatusModule} . '.' . $result->{ePDUPhaseStatusNumber};

        next if is_excluded(
            $instance,
            $self->{option_results}->{include_phase},
            $self->{option_results}->{exclude_phase}
        );

        $self->{phase}->{$instance} =
            {
                display        => $instance,
                voltage        => $result->{ePDUPhaseStatusVoltage} * 0.1,
                current        => $result->{ePDUPhaseStatusCurrent} * 0.01,
                active_power   => $result->{ePDUPhaseStatusActivePower},
                reactive_power => $result->{ePDUPhaseStatusReactivePower},
                apparent_power => $result->{ePDUPhaseStatusApparentPower},
                power_factor   => $result->{ePDUPhaseStatusPowerFactor} * 0.1,
                energy         => $result->{ePDUPhaseStatusEnergy},
            };

    }

    if (scalar(keys %{$self->{phase}}) <= 0) {
        $self->{output}->option_exit(short_msg => "No phases matching with filter found.");
    }
}

1;

__END__

=head1 MODE

Check phases current.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='active-power'>

=item B<--include-phase>

Filter phase by number (can be a regexp).
Example: C<--include-phase='1\.'>

=item B<--exclude-phase>

Exclude phase by number (can be a regexp).
Example: C<--exclude-phase='1.3'>

=item B<--warning-current>

Warning threshold. (A)

=item B<--critical-current>

Critical threshold. (A)

=item B<--warning-voltage>

Warning threshold. (V)

=item B<--critical-voltage>

Warning threshold. (V)

=item B<--warning-active-power>

Warning threshold. (W)

=item B<--critical-active-power>

Critical threshold. (W)

=item B<--warning-reactive-power>

Warning threshold. (Var)

=item B<--critical-reactive-power>

Critical threshold. (Var)

=item B<--warning-apparent-power>

Warning threshold. (VA)

=item B<--critical-apparent-power>

Critical threshold. (VA)

=item B<--warning-energy>

Warning threshold. (kWh)

=item B<--critical-energy>

Critical threshold. (kWh)

=item B<--warning-power-factor>

Warning threshold. (%)

=item B<--critical-power-factor>

Critical threshold. (%)

=back

=cut
