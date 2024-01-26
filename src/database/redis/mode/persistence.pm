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

package database::redis::mode::persistence;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("RDB save status is '%s' [progress status: %s]", $self->{result_values}->{status}, $self->{result_values}->{progress_status});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{sync_status} =~ /in progress/i',
            critical_default => '%{link_status} =~ /down/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'progress_status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'changes', nlabel => 'rdb.changes.since_last_save.count', set => {
                key_values => [ { name => 'rdb_changes_since_last_save' } ],
                output_template => 'number of changes since the last dump: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'last-save', nlabel => 'rdb.last_successful_save.seconds',set => {
                key_values => [ { name => 'rdb_last_save_time' }, { name => 'rdb_last_save_time_sec' } ],
                output_template => 'time since last successful save: %s',
                perfdatas => [
                    { value => 'rdb_last_save_time_sec', template => '%s', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'save-size', nlabel => 'rdb.last_save.size.bytes', set => {
                key_values => [ { name => 'rdb_last_cow_size' } ],
                output_template => 'size of last save: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'last-save-duration', nlabel => 'rdb.last_save.duration.seconds', set => {
                key_values => [ { name => 'rdb_last_bgsave_time' } ],
                output_template => 'duration of last save: %s s',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'current-save-duration', nlabel => 'rdb.current_save.duration.seconds', set => {
                key_values => [ { name => 'rdb_current_bgsave_time' } ],
                output_template => 'duration of current save: %s s',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my %map_status = (
    0 => 'stopped',
    1 => 'in progress'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_info();
    $self->{global} = {
        status                      => $results->{rdb_last_bgsave_status},
        progress_status             => $map_status{$results->{rdb_bgsave_in_progress}},
        rdb_changes_since_last_save => $results->{rdb_changes_since_last_save},
        rdb_last_save_time      => centreon::plugins::misc::change_seconds(value => time() - $results->{rdb_last_save_time}),
        rdb_last_save_time_sec  => time() - $results->{rdb_last_save_time},
        rdb_last_cow_size       => $results->{rdb_last_cow_size},
        rdb_last_bgsave_time    => $results->{rdb_last_bgsave_time_sec},
        rdb_current_bgsave_time => $results->{rdb_current_bgsave_time_sec}
    };
}

1;

__END__

=head1 MODE

Check RDB persistence status.

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{progress_status} =~ /in progress/i').
You can use the following variables: %{progress_status}, %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /fail/i').
You can use the following variables: %{progress_status}, %{status}

=item B<--warning-*>

Warning threshold.
Can be: 'changes', 'last-save', 'save-size', 
'last-save-duration', 'current-save-duration'.

=item B<--critical-*>

Critical threshold.
Can be: 'changes', 'last-save', 'save-size', 
'last-save-duration', 'current-save-duration'.

=back

=cut
