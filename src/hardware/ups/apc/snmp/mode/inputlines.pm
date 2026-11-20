#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::ups::apc::snmp::mode::inputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("last input line fail cause is '%s'", $self->{result_values}->{last_cause});
}

sub input_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking input line '%s' [type: %s]",
        $options{instance_value}->{inputNum},
        $options{instance_value}->{inputType}
    );
}

sub prefix_input_output {
    my ($self, %options) = @_;

    return sprintf(
        "input line '%s' [type: %s] ",
        $options{instance_value}->{inputNum},
        $options{instance_value}->{inputType}
    );
}

sub prefix_phase_output {
    my ($self, %options) = @_;

    return "phase '" . $options{instance_value}->{phaseNum} . "' [$options{instance_value}->{instance}] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, skipped_code => { NO_VALUE() => 1 } },
        {
            name               => 'inputs',
            type               => COUNTER_TYPE_MULTIPLE,
            cb_prefix_output   => 'prefix_input_output',
            cb_long_output     => 'input_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All inputs are ok',
            group              =>
                [
                    { name => 'input_global', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE() => 1 } },
                    {
                        name             => 'phases',
                        display_long     => 1,
                        cb_prefix_output => 'prefix_phase_output',
                        message_multiple => 'phases are ok',
                        type             => COUNTER_MULTIPLE_SUBINSTANCE,
                        skipped_code     => { NO_VALUE() => 1 }
                    }
                ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'voltage', nlabel => 'lines.input.voltage.volt', set => {
            key_values      => [ { name => 'voltage' } ],
            output_template => 'voltage: %s V',
            perfdatas       => [
                { template => '%s', unit => 'V' }
            ]
        }
        },
        { label => 'frequence', nlabel => 'lines.input.frequence.hertz', set => {
            key_values      => [ { name => 'frequency' } ],
            output_template => 'frequence: %s Hz',
            perfdatas       => [
                { template => '%s', unit => 'Hz' }
            ]
        }
        },
        { label => 'status', type => COUNTER_KIND_TEXT, set => {
            key_values                     => [ { name => 'last_cause' } ],
            closure_custom_output          => $self->can('custom_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold_ng
        }
        }
    ];

    $self->{maps_counters}->{input_global} = [
        { label => 'line-frequence', nlabel => 'line.input.frequence.hertz', set => {
            key_values              => [
                { name => 'frequency' },
                { name => 'inputNum' },
                { name => 'inputType' }
            ],
            output_template         => 'frequence: %s Hz',
            closure_custom_perfdata => sub {
                my ($self, %options) = @_;

                $self->{output}->perfdata_add(
                    nlabel    => $self->{nlabel},
                    unit      => 'Hz',
                    instances => [ $self->{result_values}->{inputType} . '.' . $self->{result_values}->{inputNum} ],
                    value     => sprintf('%s', $self->{result_values}->{frequency}),
                    warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                    critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                );
            }
        }
        }
    ];

    $self->{maps_counters}->{phases} = [
        { label => 'line-phase-voltage', nlabel => 'line.input.voltage.volt', set => {
            key_values              => [
                { name => 'voltage' },
                { name => 'inputNum' },
                { name => 'inputType' },
                { name => 'phaseNum' }
            ],
            output_template         => 'voltage: %s V',
            closure_custom_perfdata => sub {
                my ($self, %options) = @_;

                $self->{output}->perfdata_add(
                    nlabel    => $self->{nlabel},
                    unit      => 'V',
                    instances =>
                        [ $self->{result_values}->{inputType} . '.' . $self->{result_values}->{inputNum},
                            $self->{result_values}->{phaseNum} ],
                    value     => sprintf('%s', $self->{result_values}->{voltage}),
                    warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                    critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                );
            }
        }
        },
        { label => 'line-phase-current', nlabel => 'line.input.current.ampere', set => {
            key_values              => [
                { name => 'current' },
                { name => 'inputNum' },
                { name => 'inputType' },
                { name => 'phaseNum' }
            ],
            output_template         => 'current: %s A',
            closure_custom_perfdata => sub {
                my ($self, %options) = @_;

                $self->{output}->perfdata_add(
                    nlabel    => $self->{nlabel},
                    unit      => 'A',
                    instances =>
                        [ $self->{result_values}->{inputType} . '.' . $self->{result_values}->{inputNum},
                            $self->{result_values}->{phaseNum} ],
                    value     => sprintf('%s', $self->{result_values}->{current}),
                    warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                    critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                );
            }
        }
        },
        { label => 'line-phase-power', nlabel => 'line.input.power.watt', set => {
            key_values              => [
                { name => 'power' },
                { name => 'inputNum' },
                { name => 'inputType' },
                { name => 'phaseNum' }
            ],
            output_template         => 'power: %.2f W',
            closure_custom_perfdata => sub {
                my ($self, %options) = @_;

                $self->{output}->perfdata_add(
                    nlabel    => $self->{nlabel},
                    unit      => 'W',
                    instances =>
                        [ $self->{result_values}->{inputType} . '.' . $self->{result_values}->{inputNum},
                            $self->{result_values}->{phaseNum} ],
                    value     => sprintf('%.2f', $self->{result_values}->{power}),
                    warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
                    critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
                );
            }
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
            'include-input-type:s'  => { name => 'include_input_type' },
            'exclude-input-type:s'  => { name => 'exclude_input_type' },
            'include-input-phase:s' => { name => 'include_input_phase' },
            'exclude-input-phase:s' => { name => 'exclude_input_phase', default => '\b\d{3}\b' },
        }
    );

    return $self;
}

my $map_status = {
    1  => 'noTransfer',
    2  => 'highLineVoltage',
    3  => 'brownout',
    4  => 'blackout',
    5  => 'smallMomentarySag',
    6  => 'deepMomentarySag',
    7  => 'smallMomentarySpike',
    8  => 'largeMomentarySpike',
    9  => 'selfTest',
    10 => 'rateOfVoltageChange'
};

my $map_input_type = { 1 => 'unknown', 2 => 'main', 3 => 'bypass' };

my $mapping = {
    upsAdvInputLineVoltage       => { oid => '.1.3.6.1.4.1.318.1.1.1.3.2.1' },
    upsAdvInputFrequency         => { oid => '.1.3.6.1.4.1.318.1.1.1.3.2.4' },
    upsAdvInputLineFailCause     => { oid => '.1.3.6.1.4.1.318.1.1.1.3.2.5', map => $map_status },
    upsAdvConfigHighTransferVolt => { oid => '.1.3.6.1.4.1.318.1.1.1.5.2.2' },
    upsAdvConfigLowTransferVolt  => { oid => '.1.3.6.1.4.1.318.1.1.1.5.2.3' },
    upsHighPrecInputLineVoltage  => { oid => '.1.3.6.1.4.1.318.1.1.1.3.3.1' },
    upsHighPrecInputFrequency    => { oid => '.1.3.6.1.4.1.318.1.1.1.3.3.4' }
};
my $mapping_input = {
    frequency => { oid => '.1.3.6.1.4.1.318.1.1.1.9.2.2.1.4' },# upsPhaseInputFrequency
    type      => { oid => '.1.3.6.1.4.1.318.1.1.1.9.2.2.1.5', map => $map_input_type }# upsPhaseInputType
};
my $mapping_input_phase = {
    inputNumber     => { oid => '.1.3.6.1.4.1.318.1.1.1.9.2.3.1.1' },#  upsPhaseInputPhaseTableIndex
    inputPhaseIndex => { oid => '.1.3.6.1.4.1.318.1.1.1.9.2.3.1.2' },#  upsPhaseInputPhaseIndex
    voltage         => { oid => '.1.3.6.1.4.1.318.1.1.1.9.2.3.1.3' },# upsPhaseInputVoltage
    current         => { oid => '.1.3.6.1.4.1.318.1.1.1.9.2.3.1.6' },# upsPhaseInputCurrent
    power           => { oid => '.1.3.6.1.4.1.318.1.1.1.9.2.3.1.9' }# upsPhaseInputPower
};

sub manage_selection {
    my ($self, %options) = @_;

    # don't quit when no values are found on this OIDs. Maybe the UPS returns only the values for the phases
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    if ((!defined($self->{option_results}->{'warning-voltage'}) || $self->{option_results}->{'warning-voltage'} eq '') &&
        (!defined($self->{option_results}->{'critical-voltage'}) || $self->{option_results}->{'critical-voltage'} eq '')
    ) {
        my $th = '';
        $th .= $result->{upsAdvConfigHighTransferVolt} if (defined($result->{upsAdvConfigHighTransferVolt}) && $result->{upsAdvConfigHighTransferVolt} =~ /\d+/);
        $th = $result->{upsAdvConfigLowTransferVolt} . ':' . $th if (defined($result->{upsAdvConfigLowTransferVolt}) && $result->{upsAdvConfigLowTransferVolt} =~ /\d+/);
        $self->{perfdata}->threshold_validate(label => 'critical-voltage', value => $th) if ($th ne '');
    }

    $self->{global} = {
        last_cause => $result->{upsAdvInputLineFailCause},
        voltage    =>
            defined($result->{upsHighPrecInputLineVoltage}) && $result->{upsHighPrecInputLineVoltage} =~ /\d/ ?
                $result->{upsHighPrecInputLineVoltage} * 0.1 : $result->{upsAdvInputLineVoltage},
        frequency  =>
            defined($result->{upsHighPrecInputFrequency}) && $result->{upsHighPrecInputFrequency} =~ /\d/ ?
                $result->{upsHighPrecInputFrequency} * 0.1 : $result->{upsAdvInputFrequency},
    };

    my $oid_inputTable = '.1.3.6.1.4.1.318.1.1.1.9.2.2.1';
    $snmp_result = $options{snmp}->get_table(
        oid   => $oid_inputTable,
        start => $mapping_input->{frequency}->{oid},
        end   => $mapping_input->{type}->{oid}
    );

    $self->{inputs} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_input->{type}->{oid}\.(.*)$/);
        my $instance = $1;

        my $input_result = $options{snmp}->map_instance(
            mapping  => $mapping_input,
            results  => $snmp_result,
            instance => $instance
        );

        next if is_excluded(
            $input_result->{type},
            $self->{option_results}->{include_input_type},
            $self->{option_results}->{exclude_input_type},
            output => $self->{output}
        );

        $self->{inputs}->{$instance} = {
            inputNum     => $instance,
            inputType    => $input_result->{type},
            input_global => {
                inputNum  => $instance,
                inputType => $input_result->{type},
                frequency => defined($input_result->{frequency}) && $input_result->{frequency} != -1 ?
                    $input_result->{frequency} * 0.1 : undef
            },
            phases       => {}
        };
    }

    my $oid_inputPhaseTable = '.1.3.6.1.4.1.318.1.1.1.9.2.3.1';
    $snmp_result = $options{snmp}->get_table(
        oid   => $oid_inputPhaseTable,
        start => $mapping_input_phase->{inputNumber}->{oid},
        end   => $mapping_input_phase->{power}->{oid}
    );

    foreach my $oid (keys %$snmp_result) {
        # the OID can be (17) ".1.3.6.1.4.1.318.1.1.1.9.2.3.1.2.2.x" or ".1.3.6.1.4.1.318.1.1.1.9.2.3.1.2.2.1.x" (18)
        next if ($oid !~ /^$mapping_input_phase->{inputNumber}->{oid}\.((?:\d+\.\d+(?:\.\d+)?))$/);

        my $phase_result = $options{snmp}->map_instance(
            mapping  => $mapping_input_phase,
            results  => $snmp_result,
            instance => $1
        );

        my $phase_num = $phase_result->{inputPhaseIndex};
        my $input_num = $phase_result->{inputNumber};
        my $instance = $phase_result->{inputNumber} . $phase_result->{inputPhaseIndex};

        next if !defined($self->{inputs}->{$input_num});# input has just be excluded on inputs
        next if is_excluded(
            $instance,
            $self->{option_results}->{include_input_phase},
            $self->{option_results}->{exclude_input_phase},
            output => $self->{output}
        );

        $self->{inputs}->{$input_num}->{phases}->{$phase_num} = {
            instance  => $instance,
            inputNum  => $input_num,
            inputType => $self->{inputs}->{$input_num}->{inputType},
            phaseNum  => $phase_num,
            voltage   => defined($phase_result->{voltage}) && $phase_result->{voltage} != -1 ?
                $phase_result->{voltage} : undef,
            current   => defined($phase_result->{current}) && $phase_result->{current} != -1 ?
                $phase_result->{current} * 0.1 : undef,
            power     => defined($phase_result->{power}) && $phase_result->{power} != -1 ?
                $phase_result->{power} : undef
        };
    }
}

1;

__END__

=head1 MODE

Check input lines.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^frequence|voltage$'

=item B<--include-input-type>

Filter by input type (can be a regexp). Default: ''. Typical types are C<main> and C<bypass>

=item B<--exclude-input-type>

Exclude by input type (can be a regexp). Default: ''. Typical types are C<main> and C<bypass>

=item B<--include-input-phase>

Filter by input phase (can be a regexp). Default: ''.

=item B<--exclude-input-phase>

Exclude by input phase (can be a regexp). Default: '\b\d{3}\b'. Excludes all C<(L–L)> to get only the C<(L–N)>

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{last_cause}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{last_cause}

=item B<--warning-frequence>

Threshold in Hertz.

=item B<--critical-frequence>

Threshold in Hertz.

=item B<--warning-line-frequence>

Threshold.

=item B<--critical-line-frequence>

Threshold.

=item B<--warning-line-phase-current>

Threshold.

=item B<--critical-line-phase-current>

Threshold.

=item B<--warning-line-phase-power>

Threshold.

=item B<--critical-line-phase-power>

Threshold.

=item B<--warning-line-phase-voltage>

Threshold.

=item B<--critical-line-phase-voltage>

Threshold.

=item B<--warning-voltage>

Threshold in Volts.

=item B<--critical-voltage>

Threshold in Volts.

=back

=cut
