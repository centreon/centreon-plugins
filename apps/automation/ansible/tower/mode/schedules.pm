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

package apps::automation::ansible::tower::mode::schedules;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use DateTime;
use centreon::plugins::misc;

sub custom_start_output {
    my ($self, %options) = @_;

    return sprintf(
        'last start: %s',
        $self->{result_values}->{start_last_time} >= 0 ? centreon::plugins::misc::change_seconds(value => $self->{result_values}->{start_last_time}) : 'never'
    );
}

sub prefix_output_global {
    my ($self, %options) = @_;

    return 'Schedules ';
}

sub prefix_output_schedule {
    my ($self, %options) = @_;

    return "Schedule '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output_global' },
        { name => 'schedules', type => 1, cb_prefix_output => 'prefix_output_schedule', message_multiple => 'All schedules are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'schedules.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 }
                ]
            }
        }
    ];

    foreach ((['successful', 1], ['failed', 1], ['running', 1], ['canceled', 0], ['pending', 0], ['default', 0], ['never', 0])) {
        push @{$self->{maps_counters}->{global}}, {
                label => $_->[0], nlabel => 'schedules.' . $_->[0] . '.count', display_ok => $_->[1], set => {
                key_values => [ { name => $_->[0] }, { name => 'total' } ],
                output_template => $_->[0] . ': %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        };
    }

    $self->{maps_counters}->{schedules} = [
        {
            label => 'job-status', type => 2,
            unknown_default => '%{last_job_status} =~ /default/',
            critical_default => '%{last_job_status} =~ /failed/',
            set => {
                key_values => [ { name => 'last_job_status' }, { name => 'display' } ],
                output_template => "last job status is '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'start-last-time', nlabel => 'schedule.start.last.time.seconds', set => {
                key_values => [ { name => 'start_last_time' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_start_output'),
                perfdatas => [
                    { template => '%d', min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' }
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $schedules = $options{custom}->tower_list_schedules(add_job_status => 1);

    $self->{global} = { total => 0, failed => 0, successful => 0, canceled => 0, default => 0, pending => 0, running => 0, never => 0 };
    $self->{schedules} = {};
    foreach my $schedule (@$schedules) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' 
            && $schedule->{name} !~ /$self->{option_results}->{filter_name}/);

        my $start_last_time = -1;
        if (defined($schedule->{last_job}->{started})) {
            #2020-07-30T09:36:28.806283Z
            if ($schedule->{last_job}->{started} =~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/) {
                my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6);
                $start_last_time = time() - $dt->epoch();
            }
        }

        $self->{schedules}->{ $schedule->{id} } = {
            display => $schedule->{name},
            last_job_status => defined($schedule->{last_job}->{status}) ? $schedule->{last_job}->{status} : 'never',
            start_last_time => $start_last_time
        };
        $self->{global}->{total}++;

        if (defined($schedule->{last_job}->{status})) {
            $self->{global}->{ $schedule->{last_job}->{status} }++;
        } else {
            $self->{global}->{never}++;
        }
    }
}

1;

__END__

=head1 MODE

Check schedules.

=over 8

=item B<--filter-name>

Filter schedule name (Can use regexp).

=item B<--unknown-job-status>

Set unknown threshold for status (Default: '%{last_job_status} =~ /default/').
Can used special variables like: %{last_job_status}, %{display}

=item B<--warning-job-status>

Set warning threshold for status.
Can used special variables like: %{last_job_status}, %{display}

=item B<--critical-job-status>

Set critical threshold for status (Default: '%{last_job_status} =~ /failed/').
Can used special variables like: %{last_job_status}, %{display}

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'total', 'successful', 'failed', 'running', 'canceled', 'pending', 'default', 'never', 'start-last-time' (s).

=back

=cut
