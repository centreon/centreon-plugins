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

package centreon::common::cps::ups::snmp::mode::batterystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('battery status is %s', $self->{result_values}->{status});
}

sub custom_load_output {
    my ($self, %options) = @_;

    return sprintf("charge remaining: %s%% (%s minutes remaining)", 
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
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'charge-remaining', nlabel => 'battery.charge.remaining.percent', set => {
                key_values => [ { name => 'charge_remain' }, { name => 'minute_remain' } ],
                closure_custom_output => $self->can('custom_load_output'),
                perfdatas => [
                    { value => 'charge_remain', template => '%s', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'voltage', nlabel => 'battery.voltage.volt', display_ok => 0, set => {
                key_values => [ { name => 'voltage', no_value => 0 } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { value => 'voltage', template => '%s', unit => 'V' },
                ],
            }
        },
        { label => 'temperature', nlabel => 'battery.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'temperature', no_value => 0 } ],
                output_template => 'temperature: %s C',
                perfdatas => [
                    { value => 'temperature', template => '%s', unit => 'C' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'unknown-status:s'      => { name => 'unknown_status', default => '%{status} =~ /unknown|notPresent/i' },
        'warning-status:s'      => { name => 'warning_status', default => '%{status} =~ /low/i' },
        'critical-status:s'     => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $map_status = { 1 => 'unknown', 2 => 'normal', 3 => 'low', 4 => 'notPresent' };

my $mapping = {
    upsBaseBatteryStatus              => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.1.1', map => $map_status },
    upsAdvanceBatteryCapacity         => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.1' },
    upsAdvanceBatteryVoltage          => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.2' }, # in dV
    upsAdvanceBatteryTemperature      => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.3' }, # in degrees Centigrade
    upsAdvanceBatteryRunTimeRemaining => { oid => '.1.3.6.1.4.1.3808.1.1.1.2.2.4' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_upsBattery = '.1.3.6.1.4.1.3808.1.1.1.2';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_upsBattery, nothing_quit => 1);
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{global} = {
        voltage => (defined($result->{upsAdvanceBatteryVoltage}) && $result->{upsAdvanceBatteryVoltage} =~ /\d/) ? $result->{upsAdvanceBatteryVoltage} * 0.1 : 0,
        temperature => $result->{upsAdvanceBatteryTemperature},
        minute_remain => (defined($result->{upsAdvanceBatteryRunTimeRemaining}) && $result->{upsAdvanceBatteryRunTimeRemaining} =~ /\d/) ? ($result->{upsAdvanceBatteryRunTimeRemaining} / 100 / 60) : 'unknown',
        charge_remain => (defined($result->{upsAdvanceBatteryCapacity}) && $result->{upsAdvanceBatteryCapacity} =~ /\d/) ? $result->{upsAdvanceBatteryCapacity} : undef,
        status => $result->{upsBaseBatteryStatus},
    };
}

1;

__END__

=head1 MODE

Check battery status and charge remaining.

=over 8

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown|notPresent/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /low/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'charge-remaining' (%), 'voltage' (V), 'temperature' (C).

=back

=cut
