#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package hardware::ups::apc::snmp::mode::outputlines;

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
            $status = 'unknown';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Output status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_upsBasicOutputStatus'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
        
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'upsBasicOutputStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'load', set => {
                key_values => [ { name => 'upsAdvOutputLoad' } ],
                output_template => 'Load : %s %%',
                perfdatas => [
                    { label => 'load', value => 'upsAdvOutputLoad_absolute', template => '%s', 
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'upsAdvOutputCurrent' } ],
                output_template => 'Current : %s A',
                perfdatas => [
                    { label => 'current', value => 'upsAdvOutputCurrent_absolute', template => '%s', 
                      min => 0, unit => 'A' },
                ],
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'upsAdvOutputVoltage' } ],
                output_template => 'Voltage : %s V',
                perfdatas => [
                    { label => 'voltage', value => 'upsAdvOutputVoltage_absolute', template => '%s', 
                      unit => 'V' },
                ],
            }
        },
        { label => 'frequence', set => {
                key_values => [ { name => 'upsAdvOutputFrequency' } ],
                output_template => 'Frequence : %s Hz',
                perfdatas => [
                    { label => 'frequence', value => 'upsAdvOutputFrequency_absolute', template => '%s', 
                      unit => 'Hz' },
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
                                "warning-status:s"        => { name => 'warning_status', default => '' },
                                "critical-status:s"       => { name => 'critical_status', default => '%{status} !~ /onLine|rebooting/i' },
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

my %map_status = (
    1 => 'unknown', 2 => 'onLine', 3 => 'onBattery', 4 => 'onSmartBoost',
    5 => 'timedSleeping', 6 => 'softwareBypass', 7 => 'off',
    8 => 'rebooting', 9 => 'switchedBypass', 10 => 'hardwareFailureBypass',
    11 => 'sleepingUntilPowerReturn', 12 => 'onSmartTrim',
);

my $mapping = {
    upsBasicOutputStatus    => { oid => '.1.3.6.1.4.1.318.1.1.1.4.1.1', map => \%map_status },
    upsAdvOutputVoltage     => { oid => '.1.3.6.1.4.1.318.1.1.1.4.2.1' },
    upsAdvOutputFrequency   => { oid => '.1.3.6.1.4.1.318.1.1.1.4.2.2' },
    upsAdvOutputLoad        => { oid => '.1.3.6.1.4.1.318.1.1.1.4.2.3' },
    upsAdvOutputCurrent     => { oid => '.1.3.6.1.4.1.318.1.1.1.4.2.4' },
};
my $oid_upsOutput = '.1.3.6.1.4.1.318.1.1.1.4';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_upsOutput,
                                                nothing_quit => 1);
                                                         
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    
    foreach my $name (keys %{$mapping}) {
        $self->{global}->{$name} = $result->{$name};
    }
}

1;

__END__

=head1 MODE

Check output lines.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status|load$'

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /onLine|rebooting/i').
Can used special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'load', 'voltage', 'current', 'frequence'.

=item B<--critical-*>

Threshold critical.
Can be: 'load', 'voltage', 'current', 'frequence'.

=back

=cut
