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

package hardware::ats::apc::snmp::mode::outputbanks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ' . $self->{result_values}->{bank_state};

    return $msg;
}

sub custom_overall_status_output {
    my ($self, %options) = @_;
    my $msg = 'Overall status : ' . $self->{result_values}->{overall_state};

    return $msg;
}

sub prefix_bank_output {
    my ($self, %options) = @_;

    return "Output bank '" . $options{instance_value}->{display} . "' ";
}

sub bank_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking bank '%s'",
        $options{instance_value}->{display}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        {
            name             => 'bank',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output   => 'prefix_bank_output',
            cb_long_output     => 'bank_long_output',
            indent_long_output => '    ',
            message_multiple => 'All banks are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label            => 'overall-status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{overall_state} =~ /nearoverload/',
            critical_default => '%{overall_state} =~ /lowload|overload/',
            set              =>
                {
                    key_values                     => [
                        { name => 'overall_state' },
                        { name => 'display' }
                    ],
                    closure_custom_output          => $self->can('custom_overall_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        { label => 'total-current', nlabel => 'bank.current.ampere', set => {
            key_values      => [ { name => 'bank_current' }, { name => 'display' } ],
            output_template => 'Current : %.2f A',
            perfdatas       => [
                {
                    label  => 'current',
                    value => 'bank_current',
                    template => '%s',
                    unit => 'A',
                    label_extra_instance => 1,
                    instance_use => 'display'
                }
            ],
        }
        },
        { label => 'total-power', nlabel => 'bank.power.watt',set => {
            key_values      => [ { name => 'bank_power' }, { name => 'display' } ],
            output_template => 'Power : %.2f W',
            perfdatas       => [
                {
                    label  => 'power',
                    value => 'bank_power',
                    template => '%s',
                    unit => 'W',
                    label_extra_instance => 1,
                    instance_use => 'display'
                }
            ],
        }
        },
        { label => 'total-load-capacity', nlabel => 'bank.load.capacity.percent', set => {
            key_values      => [ { name => 'bank_load' }, { name => 'display' } ],
            output_template => 'Load capacity : %.2f %%',
            perfdatas       => [
                {
                    label  => 'load_capacity',
                    value => 'bank_load',
                    template => '%s',
                    unit => '%',
                    label_extra_instance => 1,
                    instance_use => 'display',
                    min => 0,
                    max => 100
                }
            ],
        }
        }
    ];

    $self->{maps_counters}->{bank} = [
        {
            label            => 'bank-status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{bank_state} =~ /nearoverload/',
            critical_default => '%{bank_state} =~ /lowload|overload/',
            set              =>
                {
                    key_values                     => [
                        { name => 'bank_state' },
                        { name => 'display' }
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        { label => 'bank-voltage', nlabel => 'bank.voltage.volt', display_ok => 0, set => {
            key_values      => [ { name => 'bank_voltage' }, { name => 'display' } ],
            output_template => 'Voltage : %.2f V',
            perfdatas       => [
                {
                    label  => 'voltage',
                    value => 'bank_voltage',
                    template => '%s',
                    unit => 'V',
                    label_extra_instance => 1,
                    instance_use => 'display'
                }
            ],
        }
        },
        { label => 'bank-current', nlabel => 'bank.current.ampere', display_ok => 0, set => {
            key_values      => [ { name => 'bank_current' }, { name => 'display' } ],
            output_template => 'Current : %.2f A',
            perfdatas       => [
                {
                    label  => 'current',
                    value => 'bank_current',
                    template => '%s',
                    unit => 'A',
                    label_extra_instance => 1,
                    instance_use => 'display'
                }
            ],
        }
        },
        { label => 'bank-power', nlabel => 'bank.power.watt', display_ok => 0, set => {
            key_values      => [ { name => 'bank_power' }, { name => 'display' } ],
            output_template => 'Power : %.2f W',
            perfdatas       => [
                {
                    label  => 'power',
                    value => 'bank_power',
                    template => '%s',
                    unit => 'W',
                    label_extra_instance => 1,
                    instance_use => 'display'
                }
            ],
        }
        },
        { label => 'bank-load-capacity', nlabel => 'bank.load.capacity.percent', display_ok => 0, set => {
            key_values      => [ { name => 'bank_load' }, { name => 'display' } ],
            output_template => 'Load capacity : %.2f %%',
            perfdatas       => [
                {
                    label  => 'load_capacity',
                    value => 'bank_load',
                    template => '%s',
                    unit => '%',
                    label_extra_instance => 1,
                    instance_use => 'display',
                    min => 0,
                    max => 100
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
            'include-name:s' => { name => 'include_name' },
            'exclude-name:s' => { name => 'exclude_name' }
        });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [ 'warning_status', 'critical_status' ]);
}

my $map_state = { 1 => 'normal', 2 => 'lowload', 3 => 'nearoverload', 4 => 'overload' };
my $map_bank = { 1 => 'total', 2 => 'bank1', 3 => 'bank2' };

my $mapping = {
    atsOutputBank              => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.5.1.3', map => $map_bank },
    atsOutputPhase             => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.5.1.2' },
    atsOutputBankOutputVoltage => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.5.1.6' },
    atsOutputBankCurrent       => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.5.1.4' },
    atsOutputBankPercentPower  => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.5.1.18' },
    atsOutputBankPower         => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.5.1.15' },
    atsOutputBankState         => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.5.1.5', map => $map_state },
};

my $oid_atsOutputBankEntry = '.1.3.6.1.4.1.318.1.1.8.5.4.5.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_atsOutputBankEntry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{atsOutputBank}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if $result->{atsOutputBank} ne 'total' && is_excluded(
            $result->{atsOutputBank},
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name}
        );

        my $target = {};
        $target->{display} = $result->{atsOutputBank};
        $target->{bank_phase} = $result->{atsOutputPhase};
        $target->{bank_voltage} = $result->{atsOutputBankOutputVoltage};
        $target->{bank_current} = $result->{atsOutputBankCurrent} * 0.1;
        $target->{bank_load} = $result->{atsOutputBankPercentPower};
        $target->{bank_power} = $result->{atsOutputBankPower};

        if($result->{atsOutputBank} eq 'total') {
            $self->{global} = $target;
            $self->{global}->{overall_state} = $result->{atsOutputBankState};
        } else {
            $self->{bank}->{$instance} = $target;
            $self->{bank}->{$instance}->{bank_state} = $result->{atsOutputBankState};
        }
    }

    if (!defined($self->{global}) && scalar(keys %{$self->{bank}}) <= 0) {
        $self->{output}->option_exit(short_msg => "No banks matching with filter found.");
    }
}

1;

__END__

=head1 MODE

Check output bank metrics.

=over 8

=item B<--include-name>

Filter banks by name (can be a regexp).

=item B<--exclude-name>

Exclude banks by name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^power$'

=item B<--warning-overall-status>

Define the conditions to match for the status to be WARNING (default: '%{overall_state} =~ /nearoverload/').
You can use the following variables: C<%{overall_state}>, C<%{display}>

=item B<--critical-overall-status>

Define the conditions to match for the status to be CRITICAL (default: '%{overall_state} =~ /lowload|overload/').
You can use the following variables: C<%{overall_state}>, C<%{display}>

=item B<--warning-bank-status>

Define the conditions to match for the status to be WARNING (default: '%{bank_state} =~ /nearoverload/').
You can use the following variables: C<%{bank_state}>, C<%{display}>

=item B<--critical-bank-status>

Define the conditions to match for the status to be CRITICAL (default: '%{bank_state} =~ /lowload|overload/').
You can use the following variables: C<%{bank_state}>, C<%{display}>

=item B<--warning-total-current>

Warning threshold. (A)

=item B<--critical-total-current>

Critical threshold. (A)

=item B<--warning-total-power>

Warning threshold. (W)

=item B<--critical-total-power>

Critical threshold. (W)

=item B<--warning-total-load-capacity>

Warning threshold. (%)

=item B<--critical-total-load-capacity>

Critical threshold. (%)

=item B<--warning-bank-voltage>

Warning threshold. (V)

=item B<--critical-bank-voltage>

Critical threshold. (V)

=item B<--warning-bank-current>

Warning threshold. (A)

=item B<--critical-bank-current>

Critical threshold. (A)

=item B<--warning-bank-power>

Warning threshold. (W)

=item B<--critical-bank-power>

Critical threshold. (W)

=item B<--warning-bank-load-capacity>

Warning threshold. (%)

=item B<--critical-bank-load-capacity>

Critical threshold. (%)

=back

=cut
