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

package hardware::devices::eltek::enexus::snmp::mode::battery;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use centreon::plugins::misc;

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf('status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_temperature_output { 
    my ($self, %options) = @_;

    return sprintf('temperature: %s %s',
        $self->{result_values}->{temperature},
        $self->{result_values}->{temperature_unit}
    );
}

sub custom_temperature_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'battery.temperature.' . ($self->{result_values}->{temperature_unit} eq 'C' ? 'celsius' : 'fahrenheit'),
        unit => $self->{result_values}->{temperature_unit},
        value => $self->{result_values}->{temperature},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
    );
}

sub custom_charge_remaining_output { 
    my ($self, %options) = @_;

    return sprintf('remaining capacity: %s %s',
        $self->{result_values}->{charge_remaining},
        $self->{result_values}->{charge_remaining_unit}
    );
}

sub custom_charge_remaining_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'battery.charge.remaining.' . ($self->{result_values}->{charge_remaining_unit} eq '%' ? 'percentage' : 'amperehour'),
        unit => $self->{result_values}->{charge_remaining_unit},
        value => $self->{result_values}->{charge_remaining},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{charge_remaining_unit} eq '%' ? 100 : undef
    );
}

sub custom_charge_time_output {
    my ($self, %options) = @_;

    return sprintf(
        'remaining time: %s',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{charge_remaining_time})
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'battery', type => 0, cb_prefix_output => 'prefix_battery_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{battery} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'temperature', display_ok => 0, set => {
                key_values => [ { name => 'temperature' }, { name => 'temperature_unit' } ],
                closure_custom_output => $self->can('custom_temperature_output'),
                closure_custom_perfdata => $self->can('custom_temperature_perfdata')
            }
        },
        { label => 'charge-remaining', set => {
                key_values => [ { name => 'charge_remaining' }, { name => 'charge_remaining_unit' } ],
                closure_custom_output => $self->can('custom_charge_remaining_output'),
                closure_custom_perfdata => $self->can('custom_charge_remaining_perfdata')
            }
        },
        { label => 'charge-remaining-time', nlabel => 'battery.charge.remaining.time.seconds', set => {
                key_values => [ { name => 'charge_remaining_time' } ],
                closure_custom_output => $self->can('custom_charge_time_output'),
                perfdatas => [
                    { value => 'charge_remaining_time', template => '%s', min => 0, unit => 's' },
                ],
            }
        },
        { label => 'voltage', nlabel => 'battery.voltage.volt', display_ok => 0, set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { value => 'voltage', template => '%.2f', unit => 'V' }
                ]
            }
        },
        { label => 'current', nlabel => 'battery.current.ampere', display_ok => 0, set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { value => 'current', template => '%.2f', min => 0, unit => 'A' }
                ]
            }
        }
    ];
}

sub prefix_battery_output {
    my ($self, %options) = @_;

    return 'Battery ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /minor|warning/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /error|major|critical/i' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

my $map_status = {
    0 => 'error', 1 => 'normal', 2 => 'minorAlarm', 3 => 'majorAlarm',
    4 => 'disabled', 5 => 'disconnected', 6 => 'notPresent',
    7 => 'minorAndMajor', 8 => 'majorLow', 9 => 'minorLow',
    10 => 'majorHigh', 11 => 'minorHigh', 12 => 'event',
    13 => 'valueVolt', 14 => 'valueAmp', 15 => 'valueTemp',
    16 => 'valueUnit', 17 => 'valuePerCent', 18 => 'critical',
    19 => 'warning'
};
my $map_decimal_setting = { 0 => 'ampere', 1 => 'deciAmpere' };
my $map_temp_setting = { 0 => 'celsius', 1 => 'fahrenheit' };
my $map_capacity = { 0 => 'ah', 1 => 'percent' };

my $mapping = {
    powerSystemCurrentDecimalSetting  => { oid => '.1.3.6.1.4.1.12148.10.2.15', map => $map_decimal_setting },
    powerSystemTemperatureScale       => { oid => '.1.3.6.1.4.1.12148.10.2.16', map => $map_temp_setting },
    powerSystemCapacityScale          => { oid => '.1.3.6.1.4.1.12148.10.2.17', map => $map_capacity },
    batteryStatus                     => { oid => '.1.3.6.1.4.1.12148.10.10.1', map => $map_status },
    batteryVoltageValue               => { oid => '.1.3.6.1.4.1.12148.10.10.5.5' },
    batteryVoltageMajorHighLevel      => { oid => '.1.3.6.1.4.1.12148.10.10.5.6' },
    batteryVoltageMinorHighLevel      => { oid => '.1.3.6.1.4.1.12148.10.10.5.7' }, # 0.01 for vdc
    batteryVoltageMinorLowLevel       => { oid => '.1.3.6.1.4.1.12148.10.10.5.8' },
    batteryVoltageMajorLowLevel       => { oid => '.1.3.6.1.4.1.12148.10.10.5.9' },
    batteryCurrentsValue              => { oid => '.1.3.6.1.4.1.12148.10.10.6.5' }, # A or dA
    batteryCurrentsMajorHighLevel     => { oid => '.1.3.6.1.4.1.12148.10.10.6.6' },
    batteryCurrentsMinorHighLevel     => { oid => '.1.3.6.1.4.1.12148.10.10.6.7' },
    batteryCurrentsMinorLowLevel      => { oid => '.1.3.6.1.4.1.12148.10.10.6.8' },
    batteryCurrentsMajorLowLevel      => { oid => '.1.3.6.1.4.1.12148.10.10.6.9' },
    batteryTemperaturesValue          => { oid => '.1.3.6.1.4.1.12148.10.10.7.5' }, # C or F
    batteryTemperaturesMajorHighLevel => { oid => '.1.3.6.1.4.1.12148.10.10.7.6' },
    batteryTemperaturesMinorHighLevel => { oid => '.1.3.6.1.4.1.12148.10.10.7.7' },
    batteryTemperaturesMinorLowLevel  => { oid => '.1.3.6.1.4.1.12148.10.10.7.8' },
    batteryTemperaturesMajorLowLevel  => { oid => '.1.3.6.1.4.1.12148.10.10.7.9' },
    batteryRemainingCapacityValue     => { oid => '.1.3.6.1.4.1.12148.10.10.9.5' }, # ah or %
    batteryRemainingCapacityMinorLowLevel => { oid => '.1.3.6.1.4.1.12148.10.10.9.6' },
    batteryRemainingCapacityMajorLowLevel => { oid => '.1.3.6.1.4.1.12148.10.10.9.7' },
    loadCurrentValue                      => { oid => '.1.3.6.1.4.1.12148.10.9.2.5' }, # A or dA
};

sub threshold_eltek_configured {
    my ($self, %options) = @_;

    if ((!defined($self->{option_results}->{'critical-' . $options{label}}) || $self->{option_results}->{'critical-' . $options{label}} eq '') &&
        (!defined($self->{option_results}->{'warning-' . $options{label}}) || $self->{option_results}->{'warning-' . $options{label}} eq '')) {
        my ($crit, $warn) = ('', '');
        $crit = $options{low_crit} . ':'  if (defined($options{low_crit}) && $options{low_crit} ne '');
        $crit .= $options{high_crit} if (defined($options{high_crit}) && $options{high_crit} ne '');
        $warn = $options{low_warn} . ':'  if (defined($options{low_warn}) && $options{low_warn} ne '');
        $warn .= $options{high_warn} if (defined($options{high_warn}) && $options{high_warn} ne '');
        $self->{perfdata}->threshold_validate(label => 'critical-' . $options{label}, value => $crit);
        $self->{perfdata}->threshold_validate(label => 'warning-' . $options{label}, value => $warn);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    my $scale_current = 1;
    $scale_current = 0.1 if ($result->{powerSystemCurrentDecimalSetting} eq 'deciAmpere');
    $self->{battery} = {
        status => $result->{batteryStatus},
        temperature => $result->{batteryTemperaturesValue},
        temperature_unit => $result->{powerSystemTemperatureScale} eq 'celsius' ? 'C' : 'F',
        voltage => $result->{batteryVoltageValue} * 0.01,
        current => $result->{batteryCurrentsValue} * $scale_current,
        charge_remaining => $result->{batteryRemainingCapacityValue},
        charge_remaining_unit => $result->{powerSystemCapacityScale}
    };
    # we can calculate the time remaining if unit is ah (amperehour) and current battery is discharging (negative value)
    my $current; 
    if ($result->{batteryCurrentsValue} < 0) {
        $current = $result->{batteryCurrentsValue} * -1 
    } elsif ($result->{loadCurrentValue} > 0) {
        $current = $result->{loadCurrentValue};
    }
    

    if ($result->{powerSystemCapacityScale} eq 'ah' && defined($current)) {
        $self->{battery}->{charge_remaining_time} =
            int(($result->{batteryRemainingCapacityValue} * 3600) / ($current * $scale_current));
    }

    $self->threshold_eltek_configured(
        label => 'temperature',
        high_crit => $result->{batteryTemperaturesMajorHighLevel},
        low_crit => $result->{batteryTemperaturesMajorLowLevel},
        high_warn => $result->{batteryTemperaturesMinorHighLevel},
        low_warn => $result->{batteryTemperaturesMinorLowLevel}
    );
    $self->threshold_eltek_configured(
        label => 'battery-voltage-volt',
        high_crit => $result->{batteryVoltageMajorHighLevel} * 0.01,
        low_crit => $result->{batteryVoltageMajorLowLevel} * 0.01,
        high_warn => $result->{batteryVoltageMinorHighLevel} * 0.01,
        low_warn => $result->{batteryVoltageMinorLowLevel} * 0.01
    );
    $self->threshold_eltek_configured(
        label => 'battery-current-ampere',
        high_crit => $result->{batteryCurrentsMajorHighLevel} * $scale_current,
        low_crit => $result->{batteryCurrentsMajorLowLevel} * $scale_current,
        high_warn => $result->{batteryCurrentsMinorHighLevel} * $scale_current,
        low_warn => $result->{batteryCurrentsMinorLowLevel} * $scale_current
    );
    $self->threshold_eltek_configured(
        label => 'charge-remaining',
        low_crit => $result->{batteryRemainingCapacityMajorLowLevel},
        low_warn => $result->{batteryRemainingCapacityMinorLowLevel}
    );
}

1;

__END__

=head1 MODE

Check battery.

=over 8

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /minor|warning/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /error|major|critical/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'temperature', 'voltage', 'current',
'charge-remaining', 'charge-remaining-time'.

=back

=cut
