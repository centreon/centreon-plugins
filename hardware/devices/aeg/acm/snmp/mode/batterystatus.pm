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

package hardware::devices::aeg::acm::snmp::mode::batterystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Battery charging mode is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_battChargeMode'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  },
    ];
        
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'battChargeMode' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'battVoltage' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { label => 'voltage', value => 'battVoltage', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'battCurrent' } ],
                output_template => 'Current : %s A',
                perfdatas => [
                    { label => 'current', value => 'battCurrent', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'current1', set => {
                key_values => [ { name => 'battCurrent1' } ],
                output_template => 'Current 1 : %s A',
                perfdatas => [
                    { label => 'current1', value => 'battCurrent1', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'current2', set => {
                key_values => [ { name => 'battCurrent2' } ],
                output_template => 'Current 2 : %s A',
                perfdatas => [
                    { label => 'current2', value => 'battCurrent2', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'temperature', set => {
                key_values => [ { name => 'battTemp' } ],
                output_template => 'Temperature : %s C',
                perfdatas => [
                    { label => 'temperature', value => 'battTemp', template => '%s', 
                      unit => 'C'},
                ],
            }
        },
        { label => 'temperature1', set => {
                key_values => [ { name => 'battTemp1' } ],
                output_template => 'Temperature 1 : %s C',
                perfdatas => [
                    { label => 'temperature1', value => 'battTemp1', template => '%s', 
                      unit => 'C'},
                ],
            }
        },
        { label => 'temperature2', set => {
                key_values => [ { name => 'battTemp2' } ],
                output_template => 'Temperature 2 : %s C',
                perfdatas => [
                    { label => 'temperature2', value => 'battTemp2', template => '%s', 
                      unit => 'C'},
                ],
            }
        },
        { label => 'amphourmeter', set => {
                key_values => [ { name => 'battAmpHMeter' } ],
                output_template => 'Amp Hour Meter : %s %%',
                perfdatas => [
                    { label => 'amphourmeter', value => 'battAmpHMeter', template => '%s', 
                      unit => '%'},
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
        "warning-status:s"        => { name => 'warning_status', default => '%{status} =~ /onBattery/i' },
        "critical-status:s"       => { name => 'critical_status', default => '%{status} =~ /disconnected/i || %{status} =~ /shutdown/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_battery_mode = (
    0 => 'initial',
    1 => 'float',
    2 => 'highRate',
    3 => 'dischargeTest',
    4 => 'presenceTest',
    5 => 'disconnected',
    6 => 'onBattery',
    7 => 'shutdown',
    8 => 'fallback',
    9 => 'inhibited',
);

my $mapping_acm1000 = {
    battChargeMode  => { oid => '.1.3.6.1.4.1.15416.37.1.1', map => \%map_battery_mode },
    battVoltage     => { oid => '.1.3.6.1.4.1.15416.37.1.2', divider => '100' },
    battCurrent     => { oid => '.1.3.6.1.4.1.15416.37.1.3', divider => '100' },
    battTemp        => { oid => '.1.3.6.1.4.1.15416.37.1.4', divider => '100' },
    battAmpHMeter   => { oid => '.1.3.6.1.4.1.15416.37.1.5' },
};
my $mapping_acmi1000 = {
    battChargeMode  => { oid => '.1.3.6.1.4.1.15416.38.1.1', map => \%map_battery_mode },
    battVoltage     => { oid => '.1.3.6.1.4.1.15416.38.1.2', divider => '100' },
    battCurrent1    => { oid => '.1.3.6.1.4.1.15416.38.1.4', divider => '100' },
    battCurrent2    => { oid => '.1.3.6.1.4.1.15416.38.1.5', divider => '100' },
    battTemp1       => { oid => '.1.3.6.1.4.1.15416.38.1.7', divider => '100' },
    battTemp2       => { oid => '.1.3.6.1.4.1.15416.38.1.8', divider => '100' },
    battAmpHMeter   => { oid => '.1.3.6.1.4.1.15416.38.1.9' },
};
my $mapping_acm1d = {
    battVoltage     => { oid => '.1.3.6.1.4.1.15416.29.1.1' },
    battCurrent     => { oid => '.1.3.6.1.4.1.15416.29.1.2' },
    battTemp        => { oid => '.1.3.6.1.4.1.15416.29.1.3' },
};
my $oid_acm1000Battery = '.1.3.6.1.4.1.15416.37.1';
my $oid_acmi1000Battery = '.1.3.6.1.4.1.15416.38.1';
my $oid_acm1dBattery = '.1.3.6.1.4.1.15416.29.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_acm1000Battery },
                                                                    { oid => $oid_acmi1000Battery },
                                                                    { oid => $oid_acm1dBattery },
                                                                  ],
                                                          nothing_quit => 1);
                                                         
    my $result_acm1000 = $options{snmp}->map_instance(mapping => $mapping_acm1000, results => $self->{results}->{$oid_acm1000Battery}, instance => '0');
    my $result_acmi1000 = $options{snmp}->map_instance(mapping => $mapping_acmi1000, results => $self->{results}->{$oid_acmi1000Battery}, instance => '0');
    my $result_acm1d = $options{snmp}->map_instance(mapping => $mapping_acm1d, results => $self->{results}->{$oid_acm1dBattery}, instance => '0');

    foreach my $name (keys %{$mapping_acm1000}) {
        if (defined($result_acm1000->{$name})) {
            $self->{global}->{$name} = $result_acm1000->{$name};
            $self->{global}->{$name} = $result_acm1000->{$name} / $mapping_acm1000->{$name}->{divider} if defined($mapping_acm1000->{$name}->{divider});
        }
    }
    foreach my $name (keys %{$mapping_acmi1000}) {
        if (defined($result_acmi1000->{$name})) {
            $self->{global}->{$name} = $result_acmi1000->{$name};
            $self->{global}->{$name} = $result_acmi1000->{$name} / $mapping_acmi1000->{$name}->{divider} if defined($mapping_acmi1000->{$name}->{divider});
        }
    }
    foreach my $name (keys %{$mapping_acm1d}) {
        $self->{global}->{$name} = $result_acm1d->{$name} unless (!defined($result_acm1d->{$name}));
    }
}

1;

__END__

=head1 MODE

Check battery charging mode and power statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status|current$'

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /onBattery/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /disconnected/i || %{status} =~ /shutdown/i').
Can used special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'voltage', 'current', 'current1', 'current2', 'temperature',
'temperature2', 'temperature2', 'amphourmeter'.

=item B<--critical-*>

Threshold critical.
Can be: 'voltage', 'current', 'current1', 'current2', 'temperature',
'temperature2', 'temperature2', 'amphourmeter'.

=back

=cut
