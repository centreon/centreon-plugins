#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package hardware::ups::apc::snmp::mode::batterystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "battery status is '%s' [battery needs replace: %s] [last replace date: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{replace},
        $self->{result_values}->{last_replace_date}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_upsBasicBatteryStatus'};
    $self->{result_values}->{replace} = $options{new_datas}->{$self->{instance} . '_upsAdvBatteryReplaceIndicator'};
    $self->{result_values}->{last_replace_date} = $options{new_datas}->{$self->{instance} . '_upsBasicBatteryLastReplaceDate'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'upsBasicBatteryStatus' },
                    { name => 'upsAdvBatteryReplaceIndicator' },
                    { name => 'upsBasicBatteryLastReplaceDate' }
                ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&centreon::plugins::templates::catalog_functions::catalog_status_threshold,
            }
        },
        { label => 'load', nlabel => 'battery.charge.remaining.percent', set => {
                key_values => [ { name => 'upsAdvBatteryCapacity' } ],
                output_template => 'remaining capacity: %s %%',
                perfdatas => [
                    { label => 'load', value => 'upsAdvBatteryCapacity', template => '%s', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'time', nlabel => 'battery.charge.remaining.minutes', set => {
                key_values => [ { name => 'upsAdvBatteryRunTimeRemaining' } ],
                output_template => 'remaining time: %.2f minutes',
                perfdatas => [
                    { label => 'load_time', value => 'upsAdvBatteryRunTimeRemaining', template => '%.2f', 
                      min => 0, unit => 'm' },
                ],
            }
        },
        { label => 'current', nlabel => 'battery.current.ampere', set => {
                key_values => [ { name => 'upsAdvBatteryCurrent' } ],
                output_template => 'current: %s A',
                perfdatas => [
                    { label => 'current', value => 'upsAdvBatteryCurrent', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'voltage', nlabel => 'battery.voltage.volt', set => {
                key_values => [ { name => 'upsAdvBatteryActualVoltage' } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { label => 'voltage', value => 'upsAdvBatteryActualVoltage', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'temperature', nlabel => 'battery.temperature.celsius', set => {
                key_values => [ { name => 'upsAdvBatteryTemperature' } ],
                output_template => 'temperature: %s C',
                perfdatas => [
                    { label => 'temperature', value => 'upsAdvBatteryTemperature', template => '%s', 
                      unit => 'C'},
                ],
            }
        },
        { label => 'replace-lasttime', nlabel => 'battery.replace.lasttime.seconds', display_ok => 0, set => {
                key_values => [ { name => 'last_replace_time' } ],
                output_template => 'replace last time: %s s',
                perfdatas => [
                    { label => 'replace_last_time', value => 'last_replace_time', template => '%s', 
                      unit => 's'},
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '%{status} =~ /unknown/i' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /batteryLow/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{replace} =~ /yes/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $map_battery_status = {
    1 => 'unknown', 2 => 'batteryNormal', 3 => 'batteryLow'
};
my $map_replace_status = {
    1 => 'no', 2 => 'yes'
};

my $mapping = {
    upsBasicBatteryStatus           => { oid => '.1.3.6.1.4.1.318.1.1.1.2.1.1', map => $map_battery_status },
    upsBasicBatteryTimeOnBattery    => { oid => '.1.3.6.1.4.1.318.1.1.1.2.1.2' },
    upsBasicBatteryLastReplaceDate  => { oid => '.1.3.6.1.4.1.318.1.1.1.2.1.3' },
};
my $mapping2 = {
    upsAdvBatteryCapacity           => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.1' },
    upsAdvBatteryTemperature        => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.2' },
    upsAdvBatteryRunTimeRemaining   => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.3' },
    upsAdvBatteryReplaceIndicator   => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.4', map => $map_replace_status },
    upsAdvBatteryActualVoltage      => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.8' },
    upsAdvBatteryCurrent            => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.9' },
};
my $oid_upsBasicBattery = '.1.3.6.1.4.1.318.1.1.1.2.1';
my $oid_upsAdvBattery = '.1.3.6.1.4.1.318.1.1.1.2.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_upsBasicBattery },
            { oid => $oid_upsAdvBattery },
        ],
        nothing_quit => 1
    );

    $self->{global} = {};
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_upsBasicBattery}, instance => '0');
    my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_upsAdvBattery}, instance => '0');

    $result2->{upsAdvBatteryRunTimeRemaining} = sprintf("%.0f", $result2->{upsAdvBatteryRunTimeRemaining} / 100 / 60)
        if (defined($result2->{upsAdvBatteryRunTimeRemaining}));
    $self->{global} = { %$result, %$result2 };
    if (defined($result->{upsBasicBatteryLastReplaceDate}) && $result->{upsBasicBatteryLastReplaceDate} =~ /(\d{2})\/(\d{2})\/(\d{4})/) {
        my $dt = DateTime->new(year => $3, month => $1, day => $2, hour => 0, minute => 0, second => 0);
        $self->{global}->{last_replace_time} = time() - $dt->epoch;
    }
}

1;

__END__

=head1 MODE

Check battery status and battery charge remaining.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status|load$'

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{replace}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /batteryLow/i').
Can used special variables like: %{status}, %{replace}

=item B<--critical-status>

Set critical threshold for status (Default: '%{replace} =~ /yes/i').
Can used special variables like: %{status}, %{replace}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'load', 'voltage', 'current', 
'temperature', 'time', 'replace-lasttime'.

=back

=cut
