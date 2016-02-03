#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

my $instance_mode;

sub custom_threshold_output {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        } elsif (defined($instance_mode->{option_results}->{unknown_status}) && $instance_mode->{option_results}->{unknown_status} ne '' &&
                 eval "$instance_mode->{option_results}->{unknown_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Battery status is '%s' [battery needs replace: %s]", $self->{result_values}->{status}, $self->{result_values}->{replace});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_upsBasicBatteryStatus'};
    $self->{result_values}->{replace} = $options{new_datas}->{$self->{instance} . '_upsAdvBatteryReplaceIndicator'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
        
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'upsBasicBatteryStatus' }, { name => 'upsAdvBatteryReplaceIndicator' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'load', set => {
                key_values => [ { name => 'upsAdvBatteryCapacity' } ],
                output_template => 'Remaining capacity : %s %%',
                perfdatas => [
                    { label => 'load', value => 'upsAdvBatteryCapacity_absolute', template => '%s', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'time', set => {
                key_values => [ { name => 'upsAdvBatteryRunTimeRemaining' } ],
                output_template => 'Remaining time : %s minutes',
                perfdatas => [
                    { label => 'load_time', value => 'upsAdvBatteryRunTimeRemaining_absolute', template => '%s', 
                      min => 0, unit => 'm' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'upsAdvBatteryCurrent' } ],
                output_template => 'Current : %s A',
                perfdatas => [
                    { label => 'current', value => 'upsAdvBatteryCurrent_absolute', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'upsAdvBatteryActualVoltage' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { label => 'voltage', value => 'upsAdvBatteryActualVoltage_absolute', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'temperature', set => {
                key_values => [ { name => 'upsAdvBatteryTemperature' } ],
                output_template => 'Temperature : %s C',
                perfdatas => [
                    { label => 'temperature', value => 'upsAdvBatteryTemperature_absolute', template => '%s', 
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
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "unknown-status:s"        => { name => 'unknown_status', default => '%{status} =~ /unknown/i' },
                                "warning-status:s"        => { name => 'warning_status', default => '%{status} =~ /batteryLow/i' },
                                "critical-status:s"       => { name => 'critical_status', default => '%{replace} =~ /yes/i' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status', 'unknown_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_battery_status = (
    1 => 'unknown',
    2 => 'batteryNormal',
    3 => 'batteryLow',
);
my %map_replace_status = (
    1 => 'no',
    2 => 'yes',
);

my $mapping = {
    upsBasicBatteryStatus           => { oid => '.1.3.6.1.4.1.318.1.1.1.2.1.1', map => \%map_battery_status },
    upsBasicBatteryTimeOnBattery    => { oid => '.1.3.6.1.4.1.318.1.1.1.2.1.2' },
};
my $mapping2 = {
    upsAdvBatteryCapacity           => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.1' },
    upsAdvBatteryTemperature        => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.2' },
    upsAdvBatteryRunTimeRemaining   => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.3' },
    upsAdvBatteryReplaceIndicator   => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.4', map => \%map_replace_status },
    upsAdvBatteryActualVoltage      => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.8' },
    upsAdvBatteryCurrent            => { oid => '.1.3.6.1.4.1.318.1.1.1.2.2.9' },
};
my $oid_upsBasicBattery = '.1.3.6.1.4.1.318.1.1.1.2.1';
my $oid_upsAdvBattery = '.1.3.6.1.4.1.318.1.1.1.2.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_upsBasicBattery },
                                                                    { oid => $oid_upsAdvBattery },
                                                                  ],
                                                          nothing_quit => 1);
                                                         
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_upsBasicBattery}, instance => '0');
    my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_upsAdvBattery}, instance => '0');

    $result2->{upsAdvBatteryRunTimeRemaining} = $result2->{upsAdvBatteryRunTimeRemaining} / 100 / 60 if (defined($result2->{upsAdvBatteryRunTimeRemaining}));
    
    foreach my $name (keys %{$mapping}) {
        $self->{global}->{$name} = $result->{$name};
    }
    foreach my $name (keys %{$mapping2}) {
        $self->{global}->{$name} = $result2->{$name};
    }
}

1;

__END__

=head1 MODE

Check Battery Status and battery charge remaining.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status|load$'

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{replace}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /batteryLow/i').
Can used special variables like: %{status}, %{replace}

=item B<--critical-status>

Set critical threshold for status (Default: '%{replace} =~ /yes/i').
Can used special variables like: %{status}, %{replace}

=item B<--warning-*>

Threshold warning.
Can be: 'load', 'voltage', 'current', 'temperature', 'time'.

=item B<--critical-*>

Threshold critical.
Can be: 'load', 'voltage', 'current', 'temperature', 'time'.

=back

=cut
