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

package hardware::ups::socomec::netvision::snmp::mode::battery;

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
        'charge remaining: %s%% (%s minutes remaining)', 
        $self->{result_values}->{charge_remain},
        $self->{result_values}->{minute_remain}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /low/i',
            critical_default => '%{status} =~ /depleted|failure/i',
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
                    { template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'charge-remaining-minutes', nlabel => 'battery.charge.remaining.minutes', display_ok => 0, set => {
                key_values => [ { name => 'minute_remain' } ],
                output_template => 'minutes remaining: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'current', nlabel => 'battery.current.ampere', display_ok => 0, set => {
                key_values => [ { name => 'current', no_value => 0 } ],
                output_template => 'current: %s A',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'A' }
                ]
            }
        },
        { label => 'voltage', nlabel => 'battery.voltage.volt', display_ok => 0, set => {
                key_values => [ { name => 'voltage', no_value => 0 } ],
                output_template => 'voltage: %s V',
                perfdatas => [
                    { template => '%s', unit => 'V' }
                ]
            }
        },
        { label => 'temperature', nlabel => 'battery.temperature.celsius', display_ok => 0, set => {
                key_values => [ { name => 'temperature', no_value => 0 } ],
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

my $map_status = {
    1 => 'unknown', 2 => 'normal', 3 => 'charging', 4 => 'test',
    5 => 'discharging', 6 => 'low', 7 => 'depleted', 8 => 'failure',
    9 => 'disconnected'
};

my $mapping = {
    status        => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.2.1', map => $map_status }, # upsBatteryStatus
    minute_remain => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.2.3' }, # upsEstimatedMinutesRemaining
    charge_remain => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.2.4' }, # upsEstimatedChargeRemaining
    voltage       => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.2.5' }, # upsBatteryVoltage (dV)
    temperature   => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.2.6' }, # upsBatteryTemperature (degrees Centigrade)
    current       => { oid => '.1.3.6.1.4.1.4555.1.1.7.1.2.8' }  # upsBatteryCurrent (dA)
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
    $self->{global}->{current} = (defined($self->{global}->{current}) && $self->{global}->{current} =~ /\d/ && $self->{global}->{current} != -1 && $self->{global}->{current} != 65535) ? 
        $self->{global}->{current} * 0.1 : 0;
    $self->{global}->{voltage} = (defined($self->{global}->{voltage}) && $self->{global}->{voltage} =~ /\d/ && $self->{global}->{voltage} != -1 && $self->{global}->{voltage} != 65535) ?
        $self->{global}->{voltage} * 0.1 : 0;
    $self->{global}->{temperature} = (defined($self->{global}->{temperature}) && $self->{global}->{temperature} =~ /\d/) ? $self->{global}->{temperature} * 0.1 : 0;
    $self->{global}->{minute_remain} = (defined($self->{global}->{minute_remain}) && $self->{global}->{minute_remain} =~ /\d/) ? $self->{global}->{minute_remain} : 'unknown';
    $self->{global}->{charge_remain} = (defined($self->{global}->{charge_remain}) && $self->{global}->{charge_remain} =~ /\d/) ? $self->{global}->{charge_remain} : undef;
}

1;

__END__

=head1 MODE

Check battery status and charge remaining.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /low/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /depleted|failure/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'charge-remaining' (%), 'charge-remaining-minutes',
'current' (A), 'voltage' (V), 'temperature' (C).

=back

=cut
