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

package apps::wazuh::restapi::mode::manager;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status: %s', 
        $self->{result_values}->{status},
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'process', type => 1, cb_prefix_output => 'prefix_process_output', message_multiple => 'All manager processes are ok' },
        { name => 'log', type => 1, cb_prefix_output => 'prefix_log_output', message_multiple => 'All manager logs are ok' }
    ];
    
    $self->{maps_counters}->{global} = [];
    foreach ('stopped', 'running') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'processes-' . $_, nlabel => 'manager.processes.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { value => $_ , template => '%s', min => 0 },
                ],
            }
        };
    }
    
    $self->{maps_counters}->{process} = [
        { label => 'process-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];

    $self->{maps_counters}->{log} = [];
    foreach ('error', 'critical', 'warning') {
        push @{$self->{maps_counters}->{log}}, {
            label => 'log-' . $_, nlabel => 'manager.log.' . $_ . '.count', set => {
                key_values => [ { name => $_, diff => 1 } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { value => $_ , template => '%s', min => 0 },
                ],
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, , statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-process:s' => { name => 'filter_process' },
        'filter-log:s'     => { name => 'filter_log' },
        'warning-process-status:s'  => { name => 'warning_process_status', default => '' },
        'critical-process-status:s' => { name => 'critical_process_status', default => '' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_process_status', 'critical_process_status']);
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Total processes ";
}

sub prefix_process_output {
    my ($self, %options) = @_;
    
    return "Process '" . $options{instance_value}->{display} . "' ";
}

sub prefix_log_output {
    my ($self, %options) = @_;
    
    return "Log '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { running => 0, stopped => 0 };
    $self->{process} = {};
    my $result = $options{custom}->request(path => '/manager/status');
    foreach (keys %{$result->{data}}) {
        if (defined($self->{option_results}->{filter_process}) && $self->{option_results}->{filter_process} ne '' &&
            $_ !~ /$self->{option_results}->{filter_process}/) {
            $self->{output}->output_add(long_msg => "skipping process '" . $_ . "': no matching filter.", debug => 1);
            next;
        }

        my $status = lc($result->{data}->{$_});
        $self->{process}->{$_} = {
            display => $_,
            status => $status,
        };
        
        $self->{global}->{$status}++;
    }

    $self->{log} = {};
    $result = $options{custom}->request(path => '/manager/logs/summary?');
    foreach (keys %{$result->{data}}) {
        if (defined($self->{option_results}->{filter_log}) && $self->{option_results}->{filter_log} ne '' &&
            $_ !~ /$self->{option_results}->{filter_log}/) {
            $self->{output}->output_add(long_msg => "skipping log '" . $_ . "': no matching filter.", debug => 1);
            next;
        }

        $self->{log}->{$_} = {
            display => $_,
            error => $result->{data}->{$_}->{error},
            warning => $result->{data}->{$_}->{warning},
            critical => $result->{data}->{$_}->{critical},
        };        
    }

    $self->{cache_name} = 'wazuh_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_log}) ? md5_hex($self->{option_results}->{filter_log}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check wazuh manager processes and logs.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-process>

Filter process name (can be a regexp).

=item B<--filter-log>

Filter log name (can be a regexp).

=item B<--warning-process-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-process-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'processes-running', 'processes-stopped',
'log-error', 'log-critical', 'log-warning'.

=back

=cut
