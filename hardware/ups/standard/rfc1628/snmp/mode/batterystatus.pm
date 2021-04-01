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

package hardware::ups::standard::rfc1628::snmp::mode::batterystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('battery status is %s', $self->{result_values}->{status});
}

sub custom_load_output {
    my ($self, %options) = @_;

    return sprintf(
        "charge remaining: %s%% (%s minutes remaining)", 
        $self->{result_values}->{charge_remain},
        $self->{result_values}->{minute_remain}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /low/i',
            critical_default => '%{status} =~ /depleted/i',
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'charge-remaining', nlabel => 'battery.charge.remaining.percent', set => {
                key_values => [ { name => 'charge_remain' }, { name => 'minute_remain' } ],
                closure_custom_output => $self->can('custom_load_output'),
                perfdatas => [
                    { label => 'load', template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'charge-remaining-minutes', nlabel => 'battery.charge.remaining.minutes', display_ok => 0, set => {
                key_values => [ { name => 'minute_remain' } ],
                output_template => 'minutes remaining: %s',
                perfdatas => [
                    { label => 'charge_remaining', template => '%s', min => 0, unit => 'minutes' }
                ]
            }
        },
        { label => 'current', nlabel => 'battery.current.ampere', display_ok => 0, set => {
                key_values => [ { name => 'current', no_value => 0 } ],
                output_template => 'current: %s A',
                perfdatas => [
                    { label => 'current', template => '%s', min => 0, unit => 'A' }
                ]
            }
        },
        { label => 'voltage', nlabel => 'battery.voltage.volt', display_ok => 0, set => {
                key_values => [ { name => 'voltage', no_value => 0 } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { label => 'voltage', template => '%s', unit => 'V' }
                ]
            }
        },
        { label => 'temperature', nlabel => 'battery.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'temperature', no_value => 0 } ],
                output_template => 'temperature: %s C',
                perfdatas => [
                    { label => 'temp', template => '%s', unit => 'C' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_status = { 1 => 'unknown', 2 => 'normal', 3 => 'low', 4 => 'depleted' };

my $mapping = {
    upsBatteryStatus                => { oid => '.1.3.6.1.2.1.33.1.2.1', map => $map_status },
    upsEstimatedMinutesRemaining    => { oid => '.1.3.6.1.2.1.33.1.2.3' },
    upsEstimatedChargeRemaining     => { oid => '.1.3.6.1.2.1.33.1.2.4' },
    upsBatteryVoltage               => { oid => '.1.3.6.1.2.1.33.1.2.5' }, # in dV
    upsBatteryCurrent               => { oid => '.1.3.6.1.2.1.33.1.2.6' }, # in dA
    upsBatteryTemperature           => { oid => '.1.3.6.1.2.1.33.1.2.7' }  # in degrees Centigrade
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_upsBattery = '.1.3.6.1.2.1.33.1.2';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_upsBattery, nothing_quit => 1);

    # some ups doesn't set the instance...
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result);
    if (!defined($result->{upsBatteryStatus})) {
        $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
    }

    $self->{global} = {
        current => (defined($result->{upsBatteryCurrent}) && $result->{upsBatteryCurrent} =~ /\d/) ? $result->{upsBatteryCurrent} * 0.1 : 0,
        voltage => (defined($result->{upsBatteryVoltage}) && $result->{upsBatteryVoltage} =~ /\d/) ? $result->{upsBatteryVoltage} * 0.1 : 0,
        temperature => $result->{upsBatteryTemperature},
        minute_remain => (defined($result->{upsEstimatedMinutesRemaining}) && $result->{upsEstimatedMinutesRemaining} =~ /\d/) ? $result->{upsEstimatedMinutesRemaining} : 'unknown',
        charge_remain => (defined($result->{upsEstimatedChargeRemaining}) && $result->{upsEstimatedChargeRemaining} =~ /\d/) ? $result->{upsEstimatedChargeRemaining} : undef,
        status => $result->{upsBatteryStatus}
    };
}

1;

__END__

=head1 MODE

Check battery status and charge remaining.

=over 8

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /low/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /depleted/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'charge-remaining' (%), 'charge-remaining-minutes',
'current' (A), 'voltage' (V), 'temperature' (C).

=back

=cut
