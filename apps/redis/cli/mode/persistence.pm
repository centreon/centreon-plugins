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

package apps::redis::cli::mode::persistence;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'progress_status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'changes', set => {
                key_values => [ { name => 'rdb_changes_since_last_save' } ],
                output_template => 'Number of changes since the last dump: %s',
                perfdatas => [
                    { label => 'changes', value => 'rdb_changes_since_last_save', template => '%s', min => 0 },
                ],
            },
        },
        { label => 'last-save', set => {
                key_values => [ { name => 'rdb_last_save_time' }, { name => 'rdb_last_save_time_sec' } ],
                output_template => 'Time since last successful save: %s',
                perfdatas => [
                    { label => 'last_save', value => 'rdb_last_save_time_sec', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
        { label => 'save-size', set => {
                key_values => [ { name => 'rdb_last_cow_size' } ],
                output_template => 'Size of last save: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'save_size', value => 'rdb_last_cow_size', template => '%s', min => 0, unit => 'B' },
                ],
            },
        },
        { label => 'last-save-duration', set => {
                key_values => [ { name => 'rdb_last_bgsave_time' } ],
                output_template => 'Duration of last save: %s s',
                perfdatas => [
                    { label => 'last_save_duration', value => 'rdb_last_bgsave_time', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
        { label => 'current-save-duration', set => {
                key_values => [ { name => 'rdb_current_bgsave_time' } ],
                output_template => 'Duration of current save: %s s',
                perfdatas => [
                    { label => 'current_save_duration', value => 'rdb_current_bgsave_time', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("RDB save status is '%s' [progress status: %s]", $self->{result_values}->{status}, $self->{result_values}->{progress_status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{progress_status} = $options{new_datas}->{$self->{instance} . '_progress_status'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;


     $options{options}->add_options(arguments => 
                {
                "warning-status:s"    => { name => 'warning_status', default => '%{sync_status} =~ /in progress/i' },
                "critical-status:s"   => { name => 'critical_status', default => '%{link_status} =~ /down/i' },
                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    0 => 'stopped',
    1 => 'in progress',
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

Set warning threshold for status (Default: '%{progress_status} =~ /in progress/i').
Can used special variables like: %{progress_status}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /fail/i').
Can used special variables like: %{progress_status}, %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'changes', 'last-save', 'save-size', 
'last-save-duration', 'current-save-duration'.

=item B<--critical-*>

Threshold critical.
Can be: 'changes', 'last-save', 'save-size', 
'last-save-duration', 'current-save-duration'.

=back

=cut
