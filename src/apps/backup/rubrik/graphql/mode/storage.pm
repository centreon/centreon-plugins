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

package apps::backup::rubrik::graphql::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded flatten_arrays/;
use apps::backup::rubrik::graphql::common qw/timerange_check_options $timerange_filters/;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    my $msg = sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'storage', type => COUNTER_TYPE_INSTANCE, prefix_output => "Storage for cluster '%{name}' ", message_multiple => 'All storage are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{storage} = [
        { label => 'usage', nlabel => 'storage.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used_space', template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'storage.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free_space', template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'storage.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'name'} ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'average-daily-growth', nlabel => 'storage.average.daily.growth.bytes', set => {
                key_values => [ { name => 'average_daily_growth' }, { name => 'name' } ],
                output_change_bytes => 1,
                output_template => 'average daily growth: %s %s',
                perfdatas => [
                    { template => '%d', unit => 'B', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'full-remaining-days', nlabel => 'storage.full.remaining.days.count', set => {
                key_values => [ { name => 'full_remaining_days' }, { name => 'name' } ],
                output_template => 'remaining days before filled: %s',
                perfdatas => [
                    { template => '%s', unit => 'd', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { %$timerange_filters }  );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    timerange_check_options($self);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $filters = $options{custom}->common_filters();
    $filters->{registrationTime_gt} = $self->{option_results}->{start_time}
        if $self->{option_results}->{start_time} ne '';
    $filters->{registrationTime_lt} = $self->{option_results}->{end_time}
        if $self->{option_results}->{end_time} ne '';

    my $result = $options{custom}->get_cluster_storage( filters => $filters );

    $self->{output}->option_exit(short_msg => "No matching cluster !")
        unless ref $result eq 'ARRAY';

    $self->{storage} = {};

    foreach my $cluster (@{$result}) {
        my $cluster_id = $cluster->{id} // '';
        my $cluster_name = $cluster->{name} // '';
        next if $options{custom}->is_common_excluded(id => $cluster_id, name => $cluster_name);

        my $metrics = $cluster->{metric};
        my $total = $metrics->{totalCapacity};
        $self->{storage}->{ $cluster_id } = {
                name => $cluster_name,
                used_space => $metrics->{usedCapacity},
                free_space => $metrics->{availableCapacity},
                total_space => $total,
                prct_used_space => $total ? $metrics->{usedCapacity} * 100 / $total : 100,
                prct_free_space => $total ? $metrics->{availableCapacity} * 100 / $total : 0,
                average_daily_growth => $metrics->{averageDailyGrowth},
                full_remaining_days => $cluster->{estimatedRunway}
            };
    }

    $self->{output}->option_exit(short_msg => "No matching cluster !")
        unless %{$self->{storage}};
}

1;

__END__

=head1 MODE

Check storage via GraphQL API.

=over 8

=item B<--start-time>

Set start time for filtering clusters by registration date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--end-time>

Set end time for filtering clusters by registration date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--last>

Set duration to filter last registered clusters. Use 'd' for day, 'h' for hour, 'm' for minute (e.g., C<24h>, C<30m>, C<7d>).

=item B<--warning-usage>

Warning threshold for storage usage in bytes.

=item B<--critical-usage>

Critical threshold for storage usage in bytes.

=item B<--warning-usage-free>

Warning threshold for storage free space in bytes.

=item B<--critical-usage-free>

Critical threshold for storage free space in bytes.

=item B<--warning-usage-prct>

Warning threshold for storage usage percentage (%).

=item B<--critical-usage-prct>

Critical threshold for storage usage percentage (%).

=item B<--warning-average-daily-growth>

Warning threshold for average daily growth in bytes.

=item B<--critical-average-daily-growth>

Critical threshold for average daily growth in bytes.

=item B<--warning-full-remaining-days>

Warning threshold for remaining days before storage is full.

=item B<--critical-full-remaining-days>

Critical threshold for remaining days before storage is full.

=back

=cut
