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

package hardware::ups::powerware::snmp::mode::batterystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("battery status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
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
        { label => 'charge-remaining', , nlabel => 'battery.charge.remaining.percent', set => {
                key_values => [ { name => 'xupsBatCapacity' } ],
                output_template => 'remaining capacity: %s %%',
                perfdatas => [
                    { value => 'xupsBatCapacity', template => '%s', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'charge-remaining-minutes', nlabel => 'battery.charge.remaining.minutes', display_ok => 0, set => {
                key_values => [ { name => 'xupsBatTimeRemaining' } ],
                output_template => 'remaining time: %s minutes',
                perfdatas => [
                    { value => 'xupsBatTimeRemaining', template => '%s', min => 0, unit => 'm' },
                ],
            }
        },
        { label => 'current', nlabel => 'battery.current.ampere', display_ok => 0, set => {
                key_values => [ { name => 'xupsBatCurrent', no_value => 0 } ],
                output_template => 'current: %s A',
                perfdatas => [
                    { value => 'xupsBatCurrent', template => '%s', unit => 'A' },
                ],
            }
        },
        { label => 'voltage', nlabel => 'battery.voltage.volt', display_ok => 0, set => {
                key_values => [ { name => 'xupsBatVoltage', no_value => 0 } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { value => 'xupsBatVoltage', template => '%s', unit => 'V' },
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
        'unknown-status:s'  => { name => 'unknown_status', default => '%{status} =~ /unknown/i' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /batteryDischarging/i' },
        'critical-status:s' => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $map_battery_status = {
    1 => 'batteryCharging', 2 => 'batteryDischarging',
    3 => 'batteryFloating', 4 => 'batteryResting',
    5 => 'unknown',
};

my $mapping = {
    xupsBatTimeRemaining => { oid => '.1.3.6.1.4.1.534.1.2.1' }, # in seconds
    xupsBatVoltage       => { oid => '.1.3.6.1.4.1.534.1.2.2' }, # in V
    xupsBatCurrent       => { oid => '.1.3.6.1.4.1.534.1.2.3' }, # in dA
    xupsBatCapacity      => { oid => '.1.3.6.1.4.1.534.1.2.4' },
    xupsBatteryAbmStatus => { oid => '.1.3.6.1.4.1.534.1.2.5', map => $map_battery_status },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $result->{xupsBatCurrent} = defined($result->{xupsBatCurrent}) ? $result->{xupsBatCurrent} * 0.1 : 0;
    $result->{xupsBatTimeRemaining} = defined($result->{xupsBatTimeRemaining}) ? int($result->{xupsBatTimeRemaining} / 60) : undef;
    $result->{status} = $result->{xupsBatteryAbmStatus};

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

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}.

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /batteryDischarging/i').
Can used special variables like: %{status}.

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: Can be: 'charge-remaining' (%), 'charge-remaining-minutes',
'current' (A), 'voltage' (V).

=back

=cut
