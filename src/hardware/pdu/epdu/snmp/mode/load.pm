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

package hardware::pdu::epdu::snmp::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub prefix_module_output {
    my ($self, %options) = @_;

    return sprintf(
        "Rack PDU ID '%s' [Serial: %s Model: %s Version: %s] ",
        $options{instance_value}->{display},
        $options{instance_value}->{serial_number},
        $options{instance_value}->{serial_number},
        $options{instance_value}->{version}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'pdu',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_module_output',
            message_multiple => 'All modules are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{pdu} = [
        { label => 'phases', nlabel => 'epdu.phases.count', display_ok => 1, set => {
            key_values      => [ { name => 'phases_count' }, { name => 'display' } ],
            output_template => '%d phases',
            perfdatas       => [
                {
                    template             => '%d',
                    min                  => 0,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                }
            ]
        }
        },
        { label => 'active-power', nlabel => 'epdu.power.active.watt', display_ok => 1, set => {
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
        { label => 'reactive-power', nlabel => 'epdu.power.reactive.voltampere', display_ok => 0,
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
        { label => 'apparent-power', nlabel => 'epdu.power.apparent.voltampere', display_ok => 0, set => {
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
        { label => 'energy', nlabel => 'epdu.energy.kilowatthour', display_ok => 0, set => {
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
        { label => 'power-factor', nlabel => 'epdu.power.factor.percent', display_ok => 1, set => {
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
        },
        { label => 'frequency', nlabel => 'epdu.frequency.hertz', display_ok => 1, set => {
            key_values      => [ { name => 'frequency' }, { name => 'display' } ],
            output_template => 'Frequency : %.2f Hz',
            perfdatas       => [
                {
                    template             => '%s',
                    unit                 => 'Hz',
                    min                  => 0,
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

    return $self;
}

my $mapping = {
    ePDUDeviceStatusModule        => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.2' },
    ePDUDeviceStatusVersion       => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.3' },
    ePDUDeviceStatusModelNumber   => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.4' },
    ePDUDeviceStatusSerialNumber  => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.5' },
    ePDUDeviceStatusNumPhases     => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.6' },
    ePDUDeviceStatusActivePower   => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.7' },
    ePDUDeviceStatusReactivePower => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.8' },
    ePDUDeviceStatusApparentPower => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.9' },
    ePDUDeviceStatusPowerFactor   => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.10' },
    ePDUDeviceStatusEnergy        => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.11' },
    ePDUDeviceStatusFrequency     => { oid => '.1.3.6.1.4.1.318.1.1.30.2.1.1.12' }
};

my $oid_ePDUDeviceStatusEntry = '.1.3.6.1.4.1.318.1.1.30.2.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_ePDUDeviceStatusEntry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ePDUDeviceStatusModule}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{pdu}->{$instance}->{display} = $result->{ePDUDeviceStatusModule};
        $self->{pdu}->{$instance}->{version} = $result->{ePDUDeviceStatusVersion};
        $self->{pdu}->{$instance}->{model_number} = $result->{ePDUDeviceStatusModelNumber};
        $self->{pdu}->{$instance}->{serial_number} = $result->{ePDUDeviceStatusSerialNumber};
        $self->{pdu}->{$instance}->{phases_count} = $result->{ePDUDeviceStatusNumPhases};

        if ($result->{ePDUDeviceStatusActivePower} && $result->{ePDUDeviceStatusActivePower} != -1) {
            $self->{pdu}->{$instance}->{active_power} = $result->{ePDUDeviceStatusActivePower};
        }

        if ($result->{ePDUDeviceStatusReactivePower} && $result->{ePDUDeviceStatusReactivePower} != -1) {
            $self->{pdu}->{$instance}->{reactive_power} = $result->{ePDUDeviceStatusReactivePower};
        }

        if ($result->{ePDUDeviceStatusApparentPower} && $result->{ePDUDeviceStatusApparentPower} != -1) {
            $self->{pdu}->{$instance}->{apparent_power} = $result->{ePDUDeviceStatusApparentPower};
        }

        if ($result->{ePDUDeviceStatusPowerFactor} && $result->{ePDUDeviceStatusPowerFactor} != -1) {
            $self->{pdu}->{$instance}->{power_factor} = $result->{ePDUDeviceStatusPowerFactor} * 0.1;
        }

        if ($result->{ePDUDeviceStatusEnergy} && $result->{ePDUDeviceStatusEnergy} != -1) {
            $self->{pdu}->{$instance}->{energy} = $result->{ePDUDeviceStatusEnergy} * 0.001;
        }

        if ($result->{ePDUDeviceStatusFrequency} && $result->{ePDUDeviceStatusFrequency} != -1) {
            $self->{pdu}->{$instance}->{frequency} = $result->{ePDUDeviceStatusFrequency} * 0.001;
        }
    }

    if (scalar(keys %{$self->{pdu}}) <= 0) {
        $self->{output}->option_exit(short_msg => "No pdu matching with filter found.");
    }
}

1;

__END__

=head1 MODE

Check Easy PDU performance.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='active-power'>

=item B<--warning-phases>

Warning threshold.

=item B<--critical-phases>

Critical threshold.

=item B<--warning-active-power>

Warning threshold. (W)

=item B<--critical-active-power>

Critical threshold. (W)

=item B<--warning-reactive-power>

Warning threshold. (W)

=item B<--critical-reactive-power>

Critical threshold. (W)

=item B<--warning-apparent-power>

Warning threshold. (W)

=item B<--critical-apparent-power>

Critical threshold. (W)

=item B<--warning-energy-power>

Warning threshold. (kWh)

=item B<--critical-energy-power>

Critical threshold. (kWh)

=item B<--warning-power-factor>

Warning threshold. (%)

=item B<--critical-power-factor>

Critical threshold. (%)

=item B<--warning-frequency>

Warning threshold. (Hz)

=item B<--critical-frequency>

Critical threshold. (Hz)

=back

=cut