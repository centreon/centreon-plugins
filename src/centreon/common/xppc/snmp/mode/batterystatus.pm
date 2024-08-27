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

package centreon::common::xppc::snmp::mode::batterystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf("battery status is '%s'", $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
         {
             label => 'status',
             type => 2,
             unknown_default => '%{status} =~ /unknown/i',
             warning_default => '%{status} =~ /low/i',
             set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'charge-remaining', , nlabel => 'battery.charge.remaining.percent', set => {
                key_values => [ { name => 'upsSmartBatteryCapacity' } ],
                output_template => 'remaining capacity: %s %%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'charge-remaining-minutes', nlabel => 'battery.charge.remaining.minutes', display_ok => 0, set => {
                key_values => [ { name => 'upsSmartBatteryRunTimeRemaining' } ],
                output_template => 'remaining time: %s minutes',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'm' }
                ]
            }
        },
        { label => 'voltage', nlabel => 'battery.voltage.volt', display_ok => 0, set => {
                key_values => [ { name => 'upsSmartBatteryVoltage', no_value => 0 } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { template => '%s', unit => 'V' }
                ]
            }
        },
        { label => 'temperature', nlabel => 'battery.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'upsSmartBatteryTemperature', no_value => 0 } ],
                output_template => 'temperature: %s C',
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

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_battery_status = {
    1 => 'unknown', 2 => 'normal', 3 => 'low'
};

my $mapping = {
    batteryNormal                   => { oid => '.1.3.6.1.4.1.935.1.1.1.2.1.1', map => $map_battery_status },
    upsSmartBatteryVoltage          => { oid => '.1.3.6.1.4.1.935.1.1.1.2.2.2' }, # in dV
    upsSmartBatteryTemperature      => { oid => '.1.3.6.1.4.1.935.1.1.1.2.2.3' }, # in tenth of celsius
    upsSmartBatteryRunTimeRemaining => { oid => '.1.3.6.1.4.1.935.1.1.1.2.2.4' }, # in seconds
    upsSmartBatteryCapacity         => { oid => '.1.3.6.1.4.1.935.1.1.1.2.2.1' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $result->{upsSmartBatteryVoltage} = defined($result->{upsSmartBatteryVoltage}) ? $result->{upsSmartBatteryVoltage} * 0.1 : 0;
    $result->{upsSmartBatteryTemperature} = defined($result->{upsSmartBatteryTemperature}) ? $result->{upsSmartBatteryTemperature} * 0.1 : 0;
    $result->{upsSmartBatteryRunTimeRemaining} =
        defined($result->{upsSmartBatteryRunTimeRemaining}) && $result->{upsSmartBatteryRunTimeRemaining} != 0 ? int($result->{upsSmartBatteryRunTimeRemaining} / 60) : undef;
    $result->{status} = $result->{batteryNormal};

    $self->{global} = $result;
}

1;

__END__

=head1 MODE

Check battery status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status|current'

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /unknown/i').
You can use the following variables: %{status}.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /low/i').
You can use the following variables: %{status}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '').
You can use the following variables: %{status}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: Can be: 'charge-remaining' (%), 'charge-remaining-minutes',
'temperature' (C), 'voltage' (V).

=back

=cut
