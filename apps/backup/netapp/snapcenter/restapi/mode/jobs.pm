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

package apps::backup::netapp::snapcenter::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status : %s [type: %s] [end time: %s]: %s',
        $self->{result_values}->{status},
        $self->{result_values}->{type},
        $self->{result_values}->{end_time},
        $self->{result_values}->{error},
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'jobs', type => 2, message_multiple => '0 problem(s) detected', display_counter_problem => {  nlabel => 'alerts.problems.current.count', min => 0 },
          group => [ { name => 'job', , cb_prefix_output => 'prefix_job_output', skipped_code => { -11 => 1 } } ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'jobs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total jobs : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ 
                    { name => 'status' }, { name => 'display' }, 
                    { name => 'type' }, { name => 'error' },
                    { name => 'elapsed_time' }, { name => 'end_time' }
                ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_job_output {
    my ($self, %options) = @_;
    
    return "job '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'filter-name:s'       => { name => 'filter_name' },
        'filter-type:s'       => { name => 'filter_type' },
        'filter-start-time:s' => { name => 'filter_start_time' },
        'filter-end-time:s'   => { name => 'filter_end_time', default => 86400 },
        'unknown-status:s'    => { name => 'unknown_status', default => '' },
        'warning-status:s'    => { name => 'warning_status', default => '%{status} =~ /warning/i' },
        'critical-status:s'   => { name => 'critical_status', default => '%{status} =~ /failed/i' },
        'timezone:s'          => { name => 'timezone' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'DateTime',
        error_msg => "Cannot load module 'DateTime'."
    );

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);

    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $ENV{TZ} = $self->{option_results}->{timezone};
    }
}

sub date2ts {
    my ($self, %options) = @_;

    return undef if (!defined($options{date}) || $options{date} eq '');
    if ($options{date} !~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})\s+(\d{1,2}):(\d{1,2}):(\d{2})(?:\s+(AM|PM))?/i) {
        $self->{output}->add_option_msg(short_msg => "unknown date format: $options{date}");
        $self->{output}->option_exit();
    }

    my $hour = $4;
    $hour += 12 if (defined($7) && $7 eq 'PM');
    my $dt = DateTime->new(
        year => $3, 
        month => $1, 
        day => $2, 
        hour => $4,
        minute => $5,
        second => $6
    );
    return $dt->epoch();
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(endpoint => 'jobs');

    my $map_status = {
        -1 => 'None', 0 => 'running', 1 => 'warning', 2 => 'failed', 3 => 'completed',
        4 => 'retry', 5 => 'queued', 6 => 'validating',
        7 => 'completedWithVerificationPending', 8 => 'canceled',
        9 => 'completedWithRMANCatalogingPending', 10 => 'completedWithVerificationAndRMANCatalogingPending',
        11 => 'completedPrimaryBackup', 12 => 'transferredBackupToVault',
        13 => 'cancelling',
    };
    my $map_type = {
        -1 => 'None', 0 => 'backup', 1 => 'restore', 2 => 'replication', 3 => 'retention',
        4 => 'verification', 5 => 'plug-in installation', 6 => 'clone',
        7 => 'delete clone', 8 => 'clone life cycle',
        9 => 'ressource group', 10 => 'host', 11 => 'policy', 12 => 'discovery',
        13 => 'attach policy', 14 => 'detach policy', 15 => 'storage connection', 
        16 => 'license check', 17 => 'mount backup', 18 => 'unmount backup',
        19 => 'register mount', 20 => 'get mount', 21 => 'delete mount',
        22 => 'provision', 23 => 'maintenance', 24 => 'plugin',
        25 => 'remote plugin uninstallation', 26 => 'protect snapCenter repository',
        27 => 'configure resources', 28 => 'catalog backup', 29 => 'uncatalog backup',
        30 => 'resource', 32 => 'apply protection', 33 => 'catalog', 34 => 'plugin modify',
        35 => 'repository management', 36 => 'remove protection', 37 => 'clone split',
        38 => 'server management', 39 => 'import protection', 40 => 'guest file restore',
        41 => 'extend protection', 42 => 'purge jobs', 43 => 'assign assets',
    };

    $self->{global} = { total => 0 };
    $self->{jobs}->{global} = { job => {} };

    my $current_time = time();
    foreach (@{$results->{Results}}) {
        my $type = defined($_->{Type}) && defined($map_type->{$_->{Type}}) ? $map_type->{$_->{Type}} : 'unknown';
        my $status = defined($_->{Status}) && defined($map_status->{$_->{Status}}) ? $map_status->{$_->{Status}} : 'unknown';

        my $start_ts = $self->date2ts(date => $_->{StartTime});
        my $end_ts = $self->date2ts(date => $_->{EndTime});
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{Name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $_->{Id} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $_->{Id} . "': no matching filter type.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_end_time}) && $self->{option_results}->{filter_end_time} =~ /[0-9]+/ &&
            (!defined($end_ts) || $end_ts < ($current_time - $self->{option_results}->{filter_end_time}))) {
            $self->{output}->output_add(long_msg => "skipping job '" . $_->{Id} . "': end time too old.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_start_time}) && $self->{option_results}->{filter_start_time} =~ /[0-9]+/ &&
            (!defined($start_ts) || $start_ts < ($current_time - $self->{option_results}->{filter_start_time}))) {
            $self->{output}->output_add(long_msg => "skipping job '" . $_->{Id} . "': start time too old.", debug => 1);
            next;
        }

        my $error = defined($_->{Error}) && $_->{Error} ne '' ? $_->{Error} : 'no error';
        $error =~ s/[\n\|]/ -- /msg;
        $error =~ s/[\r]//msg;
        my $elapsed_time = defined($start_ts) ? $current_time - $start_ts : -1;
        $self->{jobs}->{global}->{job}->{$_->{Id}} = {
            display => $_->{Name},
            elapsed_time => $elapsed_time, 
            status => $status,
            type => $type,
            end_time => defined($_->{EndTime}) && $_->{EndTime} ne '' ? $_->{EndTime} : -1,
            error => $error,
        };
        
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check jobs status.

=over 8

=item B<--filter-name>

Filter job name (can be a regexp).

=item B<--filter-type>

Filter job type (can be a regexp).

=item B<--filter-start-time>

Filter job with start time greater than current time less value in seconds.

=item B<--filter-end-time>

Filter job with end time greater than current time less value in seconds (Default: 86400).

=item B<--timezone>

Set timezone (If not set, we use current server execution timezone).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like:  %{display}, %{status}, %{type}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /warning/i').
Can used special variables like:  %{display}, %{status}, %{type}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{display}, %{status}, %{type}

=item B<--warning-total>

Set warning threshold for total jobs.

=item B<--critical-total>

Set critical threshold for total jobs.

=back

=cut
