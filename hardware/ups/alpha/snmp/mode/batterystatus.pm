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

package hardware::ups::alpha::snmp::mode::batterystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Battery status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_upsBatteryStatus'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
        
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'upsBatteryStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'load', set => {
                key_values => [ { name => 'upsBatteryCapacity' } ],
                output_template => 'Remaining capacity : %s %%',
                perfdatas => [
                    { label => 'load', value => 'upsBatteryCapacity', template => '%s', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'upsBatteryChargingCurrent' } ],
                output_template => 'Current : %s A',
                perfdatas => [
                    { label => 'current', value => 'upsBatteryChargingCurrent', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'upsBatteryVoltage' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { label => 'voltage', value => 'upsBatteryVoltage', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'temperature', set => {
                key_values => [ { name => 'upsBatteryTemperature' } ],
                output_template => 'Temperature : %s C',
                perfdatas => [
                    { label => 'temperature', value => 'upsBatteryTemperature', template => '%s', 
                      unit => 'C'},
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '%{status} =~ /unknown/i' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /batteryLow/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /batteryDepleted/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my %map_battery_status = (
    1 => 'unknown', 2 => 'batteryNormal', 3 => 'batteryLow', 4 => 'batteryDepleted',
);

my $mapping = {
    upsBatteryStatus            => { oid => '.1.3.6.1.4.1.7309.6.1.2.1', map => \%map_battery_status },
    upsBatteryVoltage           => { oid => '.1.3.6.1.4.1.7309.6.1.2.3' },
    upsBatteryChargingCurrent   => { oid => '.1.3.6.1.4.1.7309.6.1.2.4' },
    upsBatteryCapacity          => { oid => '.1.3.6.1.4.1.7309.6.1.2.5' },
    upsBatteryTemperature       => { oid => '.1.3.6.1.4.1.7309.6.1.2.6' },
};
my $oid_upsBattery = '.1.3.6.1.4.1.7309.6.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_upsBattery,
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $result->{upsBatteryVoltage} *= 0.1;
    $result->{upsBatteryChargingCurrent} *= 0.1;
    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check battery status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status|load$'

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /batteryLow/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /batteryDepleted/i').
Can used special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'load', 'voltage', 'current', 'temperature'.

=item B<--critical-*>

Threshold critical.
Can be: 'load', 'voltage', 'current', 'temperature'.

=back

=cut
