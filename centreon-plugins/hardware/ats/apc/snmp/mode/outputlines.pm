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

package hardware::ats::apc::snmp::mode::outputlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'oline', type => 1, cb_prefix_output => 'prefix_line_output', message_multiple => 'All output lines are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{oline} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'atsOutputPhaseState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'voltage', set => {
                key_values => [ { name => 'atsOutputVoltage' }, { name => 'display' } ],
                output_template => 'Voltage : %.2f V',
                perfdatas => [
                    { label => 'voltage', value => 'atsOutputVoltage_absolute', template => '%s', 
                      unit => 'V', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'current', set => {
                key_values => [ { name => 'atsOutputCurrent' }, { name => 'display' } ],
                output_template => 'Current : %.2f A',
                perfdatas => [
                    { label => 'current', value => 'atsOutputCurrent_absolute', template => '%s', 
                      unit => 'A', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'power', set => {
                key_values => [ { name => 'atsOutputPower' }, { name => 'display' } ],
                output_template => 'Power : %.2f W',
                perfdatas => [
                    { label => 'power', value => 'atsOutputPower_absolute', template => '%s', 
                      unit => 'W', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'load', set => {
                key_values => [ { name => 'atsOutputLoad' }, { name => 'display' } ],
                output_template => 'Load : %.2f VA',
                perfdatas => [
                    { label => 'load', value => 'atsOutputLoad_absolute', template => '%s', 
                      unit => 'VA', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'load-capacity', set => {
                key_values => [ { name => 'atsOutputPercentLoad' }, { name => 'display' } ],
                output_template => 'Load capacity : %.2f %%',
                perfdatas => [
                    { label => 'load_capacity', value => 'atsOutputPercentLoad_absolute', template => '%s', 
                      unit => '%', label_extra_instance => 1, instance_use => 'display_absolute', min => 0, max => 100 },
                ],
            }
        },
    ];
}

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
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ' . $self->{result_values}->{status};
    
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_atsOutputPhaseState'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub prefix_line_output {
    my ($self, %options) = @_;
    
    return "Output Line '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "warning-status:s"        => { name => 'warning_status', default => '%{status} =~ /nearoverload/' },
                                "critical-status:s"       => { name => 'critical_status', default => '%{status} =~ /^(lowload|overload)$/' },
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
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_state = (1 => 'normal', 2 => 'lowload', 3 => 'nearoverload', 4 => 'overload');

my $mapping = {
    atsOutputVoltage        => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.3.1.3', factor => 1 },
    atsOutputCurrent        => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.3.1.4', factor => 0.1 },
    atsOutputLoad           => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.3.1.7', factor => 1 },
    atsOutputPercentLoad    => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.3.1.10', factor => 1 },
    atsOutputPower          => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.3.1.13', factor => 1 },
    atsOutputPhaseState     => { oid => '.1.3.6.1.4.1.318.1.1.8.5.4.3.1.19', map => \%map_state },
};

my $oid_atsOutputPhaseEntry = '.1.3.6.1.4.1.318.1.1.8.5.4.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(oids => [ 
                                                                { oid => $oid_atsOutputPhaseEntry },
                                                     ],
                                                     nothing_quit => 1);
    
    $self->{oline} = {};
    foreach my $oid (keys %{$results->{$oid_atsOutputPhaseEntry}}) {
        next if ($oid !~ /^$mapping->{atsOutputVoltage}->{oid}\.(\d+)\.(.*)$/);
        my ($output_index, $phase_index) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results->{$oid_atsOutputPhaseEntry}, instance => $output_index . '.' . $phase_index);
        
        my $name = $output_index . '.' . $phase_index;
        $self->{oline}->{$name} = { display => $name };
        foreach (keys %{$mapping}) {
            if (defined($mapping->{$_}->{factor})) {
                $result->{$_} = undef if (defined($result->{$_}) && $result->{$_} == -1);
                $result->{$_} *= $mapping->{$_}->{factor} if (defined($result->{$_}));
            }
            $self->{oline}->{$name}->{$_} = $result->{$_};
        }
    }
}

1;

__END__

=head1 MODE

Check output phase metrics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^power$'

=item B<--warning-*>

Threshold warning.
Can be: 'voltage', 'current', 'power', 'load', 'load-capacity'.

=item B<--critical-*>

Threshold critical.
Can be: 'voltage', 'current', 'power', 'load', 'load-capacity'.

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /nearoverload/').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /^(lowload|overload)$/').
Can used special variables like: %{status}, %{display}

=back

=cut
