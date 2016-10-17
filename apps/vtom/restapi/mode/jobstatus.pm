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

package apps::vtom::restapi::mode::jobstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

my $instance_mode;

sub custom_status_threshold {
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
    my $msg = 'status : ' . $self->{result_values}->{status};
    if ($self->{result_values}->{information} ne '') {
        $msg .= ' [information: ' . $self->{result_values}->{information} . ']';
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{exit_code} = $options{new_datas}->{$self->{instance} . '_exit_code'};
    $self->{result_values}->{family} = $options{new_datas}->{$self->{instance} . '_family'};
    $self->{result_values}->{information} = $options{new_datas}->{$self->{instance} . '_information'};
    
    return 0;
}

sub custom_long_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_long}) && $instance_mode->{option_results}->{critical_long} ne '' &&
            eval "$instance_mode->{option_results}->{critical_long}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_long}) && $instance_mode->{option_results}->{warning_long} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_long}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_long_output {
    my ($self, %options) = @_;
    my $msg = 'started since : ' . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{elapsed});

    return $msg;
}

sub custom_long_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{elapsed} = $options{new_datas}->{$self->{instance} . '_elapsed'};
    $self->{result_values}->{family} = $options{new_datas}->{$self->{instance} . '_family'};
    
    return -11 if ($self->{result_values}->{status} !~ /Running/i);

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'job', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok', , skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'exit_code' }, { name => 'family' }, { name => 'information' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'long', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' }, { name => 'elapsed' }, { name => 'family' } ],
                closure_custom_calc => $self->can('custom_long_calc'),
                closure_custom_output => $self->can('custom_long_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_long_threshold'),
            }
        },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-error', set => {
                key_values => [ { name => 'error' }, { name => 'total' } ],
                output_template => 'Error : %s',
                perfdatas => [
                    { label => 'total_error', value => 'error_absolute', template => '%s',
                      min => 0, max => 'total_absolute' },
                ],
            }
        },
        { label => 'total-running', set => {
                key_values => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'Running : %s',
                perfdatas => [
                    { label => 'total_running', value => 'running_absolute', template => '%s',
                      min => 0, max => 'total_absolute' },
                ],
            }
        },
        { label => 'total-unplanned', set => {
                key_values => [ { name => 'unplanned' }, { name => 'total' } ],
                output_template => 'Unplanned : %s',
                perfdatas => [
                    { label => 'total_unplanned', value => 'unplanned_absolute', template => '%s',
                      min => 0, max => 'total_absolute' },
                ],
            }
        },
        { label => 'total-finished', set => {
                key_values => [ { name => 'finished' }, { name => 'total' } ],
                output_template => 'Finished : %s',
                perfdatas => [
                    { label => 'total_finished', value => 'finished_absolute', template => '%s',
                      min => 0, max => 'total_absolute' },
                ],
            }
        },
        { label => 'total-coming', set => {
                key_values => [ { name => 'coming' }, { name => 'total' } ],
                output_template => 'Coming : %s',
                perfdatas => [
                    { label => 'total_coming', value => 'coming_absolute', template => '%s',
                      min => 0, max => 'total_absolute' },
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
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "filter-family:s"         => { name => 'filter_family' },
                                  "warning-status:s"        => { name => 'warning_status' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} =~ /Error/i' },
                                  "warning-long:s"          => { name => 'warning_long' },
                                  "critical-long:s"         => { name => 'critical_long' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Total Job ";
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return "job '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status', 'warning_long', 'critical_long')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %mapping_job_status = (
    R => 'Running',
    U => 'Unplanned',
    F => 'Finished',
    W => 'Coming',
    E => 'Error',
);

sub manage_selection {
    my ($self, %options) = @_;
 
    $self->{job} = {};
    $self->{global} = { total => 0, running => 0, unplanned => 0, finished => 0, coming => 0, error => 0 };
    my $result = $options{custom}->get(path => '/api/job/getAll');
    
    my $current_time = time();
    if (defined($result->{result})) {
        foreach my $entry (@{$result->{result}}) {
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $entry->{name} !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $entry->{name} . "': no matching filter.", debug => 1);
                next;
            }
            my $family = defined($entry->{family}) ? $entry->{family} : '-';
            if (defined($self->{option_results}->{filter_family}) && $self->{option_results}->{filter_family} ne '' &&
                $family !~ /$self->{option_results}->{filter_family}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $family . "': no matching filter.", debug => 1);
                next;
            }
            
            my $information = defined($entry->{information}) ? $entry->{information} : '';
            $information =~ s/\|/-/msg;
            my $elapsed_time = $current_time - $entry->{timeBegin};
            
            $self->{global}->{total} += 1;
            $self->{global}->{lc($mapping_job_status{$entry->{status}})} += 1;
            $self->{job}->{$entry->{id}} = { 
                display => $entry->{name}, 
                status => $mapping_job_status{$entry->{status}}, information => $information,
                exit_code => $entry->{retcode},
                family => $family,
                elapsed => $elapsed_time
            };
        }
    }
    
    if (scalar(keys %{$self->{job}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No job found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check job status.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--filter-family>

Filter family (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-error$'

=item B<--warning-*>

Threshold warning.
Can be: 'total-error', 'total-running', 'total-unplanned',
'total-finished', 'total-coming'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-error', 'total-running', 'total-unplanned',
'total-finished', 'total-coming'.

=item B<--warning-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{display}, %{status}, 
%{exit_code}, %{family}, %{information}

=item B<--critical-status>

Set critical threshold for status (Default: '%{exit_code} =~ /Error/i').
Can used special variables like: %{display}, %{status}, 
%{exit_code}, %{family}, %{information}

=item B<--warning-long>

Set warning threshold for long jobs (Default: none)
Can used special variables like: %{display}, %{status}, %{elapsed}, %{family}

=item B<--critical-long>

Set critical threshold for long jobs (Default: none).
Can used special variables like: %{display}, %{status}, %{elapsed}, %{family}

=back

=cut
