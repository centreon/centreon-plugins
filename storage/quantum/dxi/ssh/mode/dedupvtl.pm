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

package storage::quantum::dxi::ssh::mode::dedupvtl;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Status is '%s' [State: %s], Duration: %s, Percent complete: %s%%",
        $self->{result_values}->{status}, $self->{result_values}->{state},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{duration}),
        $self->{result_values}->{percent_complete}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{start_time} = $options{new_datas}->{$self->{instance} . '_start_time'};
    $self->{result_values}->{completion_time} = $options{new_datas}->{$self->{instance} . '_completion_time'};
    $self->{result_values}->{percent_complete} = $options{new_datas}->{$self->{instance} . '_percent_complete'};

    my ($start, $end);
    my %months = ("Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4, "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8, "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12);
    if (defined($self->{result_values}->{start_time}) && $self->{result_values}->{start_time} =~ /^(\w+)\s(\w+)\s+(\d+)\s(\d+):(\d+):(\d+)\s(\d+)$/) { # Mon Jan  1 13:01:23 2018 or Mon Jan 15 13:01:23
        $start = DateTime->new(year => $7, month => $months{$2}, day => $3, hour => $4, minute => $5, second => $6);
    }
    if (defined($self->{result_values}->{completion_time}) && $self->{result_values}->{completion_time} =~ /^(\w+)\s(\w+)\s+(\d+)\s(\d+):(\d+):(\d+)\s(\d+)$/) {
        $end = DateTime->new(year => $7, month => $months{$2}, day => $3, hour => $4, minute => $5, second => $6);
    }

    $self->{result_values}->{duration} = 0;
    $self->{result_values}->{duration} = $end->epoch() - $start->epoch() if (defined($end));
    $self->{result_values}->{duration} = time() - $start->epoch() if (defined($start) && !defined($end));

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "VTL deduplication '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All VTL deduplication are ok', message_separator => ' - ' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'status' }, { name => 'state' }, { name => 'start_time' },
                    { name => 'completion_time' }, { name => 'percent_complete' }, { name => 'name' }
                ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'original-data-size', set => {
                key_values => [ { name => 'original_size' }, { name => 'name' }  ],
                output_template => 'Original data size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'original_data_size', value => 'original_size', template => '%d',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'sent-data-size', set => {
                key_values => [ { name => 'sent_size' }, { name => 'name' }  ],
                output_template => 'Sent data size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'sent_data_size', value => 'sent_size', template => '%d',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' },
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
        'warning-status:s'  => { name => 'warning_status', default => '%{state} !~ /Enabled/i' },
        'critical-status:s' => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = $options{custom}->execute_command(command => 'syscli --list dedupvtl');
    # Output data:
    # List of all deduped VTL on source:
    # Total count = 2
    # [dedupvtl = 1]
    #     VTL name = Library_DC1
    #     Replication type  = SYNCHRONIZATION
    #     Replication state = Enabled
    #     Replication sync id = Library_DC1
    #     Replication target = 1.2.3.5
    #     Replication start = Tue Jun 12 11:00:36 2018
    #     Replication completion = Wed Jun 13 09:22:14 2018
    #     Replication status = SUCCESS
    #     Percent complete = 0
    #     Estimated completion time = No time remaining.
    #     Original data size = 159591544529360
    #     Actual data sent = 653312931536
    #     Average data sent = 8.63815e+06
    # [dedupvtl = 2]
    #     VTL name = vtl_dc1_plat
    #     Replication type  = SYNCHRONIZATION
    #     Replication state = Enabled
    #     Replication sync id = vtl_dc1_plat
    #     Replication target = 1.2.3.4
    #     Replication start = Tue Jun 12 10:38:01 2018
    #     Replication completion = Tue Jun 12 11:06:36 2018
    #     Replication status = SUCCESS
    #     Percent complete = 2
    #     Estimated completion time = No time remaining.
    #     Original data size = 162997086504
    #     Actual data sent = 4352486416
    #     Average data sent = 1.9672e+07

    $self->{global} = {};
    my $id;
    foreach (split(/\n/, $stdout)) {
        $id = $1 if (/.*\[dedupvtl\s=\s(.*)\]$/i);
        $self->{global}->{$id}->{name} = $1 if (/.*VTL\sname\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{state} = $1 if (/.*Replication\sstate\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{start_time} = $1 if (/.*Replication\sstart\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{completion_time} = $1 if (/.*Replication\scompletion\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{status} = $1 if (/.*Replication\sstatus\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{percent_complete} = $1 if (/.*Percent\scomplete\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{original_size} = $1 if (/.*Original\sdata\ssize\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{sent_size} = $1 if (/.*Actual\sdata\ssent\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{status} = "-" if (defined($id) && $id ne '' && !defined($self->{global}->{$id}->{status}));
        $self->{global}->{$id}->{start_time} = "-" if (defined($id) && !defined($self->{global}->{$id}->{start_time}));
        $self->{global}->{$id}->{completion_time} = "-" if (defined($id) && !defined($self->{global}->{$id}->{completion_time}));
    }
}

1;

__END__

=head1 MODE

Check deduped VTL on source.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-status>

Set warning threshold for status (Default: '%{state} !~ /Enabled/i').
Can used special variables like: %{status}, %{state}, %{duration}, %{percent_complete}.

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}, %{state}, %{duration}, %{percent_complete}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'original-data-size', 'sent-data-size'.

=back

=cut
