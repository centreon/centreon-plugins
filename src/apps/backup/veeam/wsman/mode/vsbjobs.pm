#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::backup::veeam::wsman::mode::vsbjobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::veeam::vsbjobs;
use apps::backup::veeam::wsman::mode::resources::types qw($job_type $job_result);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'last status: %s [duration: %s]',
        $self->{result_values}->{status},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration})
    );
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return sprintf(
        "SureBackup job '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of SureBackup jobs ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'jobs', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All SureBackup jobs are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'jobs-detected', nlabel => 'sure_backup.jobs.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected jobs: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'jobs-success', nlabel => 'sure_backup.jobs.success.count', set => {
                key_values => [ { name => 'success' } ],
                output_template => 'success: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'jobs-failed', nlabel => 'sure_backup.jobs.failed.count', set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'failed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'jobs-warning', nlabel => 'sure_backup.jobs.warning.count', set => {
                key_values => [ { name => 'warning' } ],
                output_template => 'warning: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{jobs} = [
        { label => 'status', type => 2, critical_default => 'not %{status} =~ /success/i', set => {
                key_values => [
                    { name => 'name' }, { name => 'type' },
                    { name => 'status' }, { name => 'duration' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'filter-name:s'     => { name => 'filter_name' },
        'exclude-name:s'    => { name => 'exclude_name' },
        'filter-type:s'     => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $ps = centreon::common::powershell::veeam::vsbjobs::get_powershell();
    if (defined($self->{option_results}->{ps_display})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $ps
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $result = $options{wsman}->execute_powershell(
        label => 'vsbjobs',
        content => centreon::plugins::misc::powershell_encoded($ps)
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $result->{vsbjobs}->{stdout}
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($self->{output}->decode($result->{vsbjobs}->{stdout}));
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #  { name: 'xxxx', type: 0, result: 0, creationTimeUTC: 1512875246.2, endTimeUTC: 1512883615.377 },
    #  { name: 'xxxx', type: 0, result: 1, creationTimeUTC: '', endTimeUTC: '' },
    #  { name: 'xxxx', type: 1, result: 0, creationTimeUTC: 1513060425.027, endTimeUTC: -2208992400 }
    #]

    $self->{global} = { detected => 0, success => 0, failed => 0, warning => 0 };
    $self->{jobs} = {};
    my $current_time = time();
    foreach my $job (@$decoded) {
        $job->{creationTimeUTC} =~ s/,/\./;
        $job->{endTimeUTC} =~ s/,/\./;

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne '' &&
            $job->{name} =~ /$self->{option_results}->{exclude_name}/);

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter type.", debug => 1);
            next;
        }
        # Sometimes we may get such JSON: [{"lastResult":null,"name":null,"lastState":null,"type":null,"enabled":null}]
        if (!defined($job->{name})) {
            $self->{output}->output_add(long_msg => "skipping nulled job (empty json)", debug => 1);
            next;            
        }

        my $elapsed_time = 0;
        $elapsed_time = $current_time - $job->{creationTimeUTC} if ($job->{creationTimeUTC} =~ /[0-9]/);

        my $status = defined($job_result->{ $job->{result} }) && $job_result->{ $job->{result} } ne '' ? $job_result->{ $job->{result} } : '-';
        $self->{jobs}->{ $job->{name} } = {
            name => $job->{name},
            type => defined($job_type->{ $job->{type} }) ? $job_type->{ $job->{type} } : 'unknown',
            duration => $elapsed_time,
            status => $status
        };
        $self->{global}->{$status}++ if (defined($self->{global}->{$status}));
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

[EXPERIMENTAL] Monitor SureBackup jobs.

=over 8


=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-name>

Filter job name (can be a regexp).

=item B<--exclude-name>

Exclude job name (regexp can be used).

=item B<--filter-type>

Filter job type (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{name}, %{type}, %{status}, %{duration}.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{name}, %{type}, %{status}, %{duration}.

=item B<--critical-status>

Set critical threshold for status (Default: 'not %{status} =~ /success/i').
Can used special variables like: %{name}, %{type}, %{status}, %{duration}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'jobs-detected', 'jobs-success', 'jobs-warning', 'jobs-failed'.

=back

=cut
