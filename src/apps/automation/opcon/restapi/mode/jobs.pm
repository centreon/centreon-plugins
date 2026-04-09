#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::automation::opcon::restapi::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::constants qw(:counters :values);
use Digest::MD5 qw(md5_hex);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of jobs ';
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return sprintf(
        "job '%s' executions ",
        $options{instance_value}->{jobId}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'jobs', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok' }
    ];

    $self->{maps_counters}->{global} = [
        {   label => 'jobs-detected', display_ok => 0, nlabel => 'jobs.detected.count',
            unknown_default => '@0',
            set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{jobs} = [
        { label => 'job-executions-failed-prct', nlabel => 'job.executions.failed.percentage', set => {
                key_values => [ { name => 'jobFailedPrct' }, { name => 'jobId' } ],
                output_template => 'failed: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'jobId' }
                ]
            }
        },
        { label => 'job-executions', nlabel => 'job.executions.count', set => {
                key_values => [ { name => 'jobCount' }, { name => 'jobId' } ],
                output_template => 'count: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'jobId' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'     => { name => 'filter_id', default => '' },
        'filter-name:s'   => { name => 'filter_name', default => '' },
        'timezone:s'      => { name => 'timezone' },
        'status-failed:s' => { name => 'status_failed' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{timezone} = 'UTC' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');

    if (!defined($self->{option_results}->{status_failed}) || $self->{option_results}->{status_failed} eq '') {
        $self->{option_results}->{status_failed} = '%{statusDesc} =~ /initialization error|failed/i';
    }

    $self->{option_results}->{status_failed} =~ s/%\{(.*?)\}/\$values->{$1}/g;
    $self->{option_results}->{status_failed} =~ s/%\((.*?)\)/\$values->{$1}/g;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'opcon_' . $self->{mode} . '_' . $options{custom}->get_connection_info() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
            (defined($self->{option_results}->{filter_id}) ? $self->{option_results}->{filter_id} : '') . '_' .
            (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
            (defined($self->{option_results}->{filter_type}) ? $self->{option_results}->{filter_type} : '')
        );

    my $ctime = time();
    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    $last_timestamp = $ctime - (15 * 60) if (!defined($last_timestamp));

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    my $dt = DateTime->from_epoch(epoch => $ctime, %$tz);
    my $to = sprintf("%02d-%02d-%d", $dt->day, $dt->month, $dt->year);
    my $dt2 = DateTime->from_epoch(epoch => $last_timestamp, %$tz);
    my $from = sprintf("%02d-%02d-%d", $dt2->day, $dt2->month, $dt2->year);
    my ($items, $update_time) = $options{custom}->get_jobHistories(
        get_param => [
            'from=' . $from,
            'to=' . $to
        ]
    );

    my $filter_time = $last_timestamp;
    if (defined($update_time) && $update_time < $filter_time) {
        $filter_time = $update_time;
    }

    my ($masterJobs) = $options{custom}->get_masterJobs();

    $self->{global} = { detected => 0 };
    $self->{jobs} = {};

    foreach my $item (@$masterJobs) {
        my ($masterId, $name) = split(/\|/, $item->{id});
        my $id = $masterId . '-' . $name;

        next if is_excluded($id, $self->{option_results}->{filter_id});        
        next if is_excluded($item->{name}, $self->{option_results}->{filter_name});

        $self->{jobs}->{$id} = {
            jobId => $id,
            jobName => $item->{name},
            jobCount => 0,
            jobFailed => 0
        };
        $self->{global}->{detected}++;
    }

    foreach my $item (@$items) {
        my ($date, $masterId, $jobNumber, $name) = split(/\|/, $item->{id});
        my $id = $masterId . '-' . $name;
        next if is_excluded($id, $self->{option_results}->{filter_id});
        next if is_excluded($item->{name}, $self->{option_results}->{filter_name});

        # format: "2026-04-08T12:01:46.7400000+02:00"
        next if ($item->{terminationTime} !~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\.\d+(\+.*)$/);
        my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, time_zone => $7);
        my $termination_epoch = $dt->epoch();

        next if ($filter_time > $termination_epoch);

        $self->{jobs}->{$id}->{jobCount}++;

        $self->{jobs}->{$id}->{jobFailed}++ if ($self->{output}->test_eval(test => $self->{option_results}->{status_failed}, values => { statusDesc => $item->{statusDesc} }));
    }

    foreach my $id (keys %{$self->{jobs}}) {
        $self->{jobs}->{$id}->{jobFailedPrct} = $self->{jobs}->{$id}->{jobCount} > 0 ?
            $self->{jobs}->{$id}->{jobFailed} * 100 / $self->{jobs}->{$id}->{jobCount} : 0;
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'masterId', 'name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my ($masterJobs) = $options{custom}->get_masterJobs();
    foreach (sort { $a->{id} cmp $b->{id} } values %{ $self->{jobs} }) {
        my ($masterId, $name) = split(/\|/, $_->{id});
        my $id = $masterId . '-' . $name;

        $self->{output}->add_disco_entry(
            id => $id,
            masterId => $masterId,
            name => $_->{name}
        );
    }
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--filter-id>

Filter jobs by ID (can be a regexp).

=item B<--filter-name>

Filter jobs by name (can be a regexp).

=item B<--timezone>

Timezone options. Default is 'UTC'.

=item B<--status-failed>

Expression to define status failed (default: '%{statusDesc} =~ /initialization error|failed/i').

=item B<--warning-jobs-detected>

Threshold.

=item B<--critical-jobs-detected>

Threshold.

=item B<--warning-job-executions>

Threshold.

=item B<--critical-job-executions>

Threshold.

=item B<--warning-job-executions-failed-prct>

Threshold in percentage.

=item B<--critical-job-executions-failed-prct>

Threshold in percentage.

=back

=cut
