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

package apps::backup::rubrik::graphql::mode::disks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use apps::backup::rubrik::graphql::common qw/timerange_check_options $timerange_filters/;
use centreon::plugins::misc qw/is_excluded/;

sub custom_status_output {
    my ($self, %options) = @_;

    my $status = 'status: ' . $self->{result_values}->{status};

    if ($self->{output}->is_verbose()) {
        $status .= ", path: '". $self->{result_values}->{path}."'";
        $status .= ', encrypted: '. $self->{result_values}->{is_encrypted};
        $status .= ', raid: '. $self->{result_values}->{raid_type};
        $status .= ' ('.$self->{result_values}->{raid_status}.')' if $self->{result_values}->{raid_type} ne 'none';
    }

    return $status;
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return "Checking cluster '" . $options{instance_value}->{name} . "'";
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance_value}->{id} . "' ";
}

sub prefix_global_cluster_output {
    my ($self, %options) = @_;

    return 'disks ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok',
            group => [
                { name => 'cluster', type => COUNTER_MULTIPLE_INSTANCE, cb_prefix_output => 'prefix_global_cluster_output' },
                { name => 'disks', type => COUNTER_MULTIPLE_SUBINSTANCE, display_long => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'disks are ok', skipped_code => { NO_VALUE() => 1 } }
            ]
        }
    ];
    $self->{maps_counters}->{cluster} = [
        { label => 'cluster-disks-total', nlabel => 'cluster.disks.total.count', display_ok => 0, set => {
                key_values => [ { name => 'disks_total' }, { name => 'name'} ],
                output_template => 'total %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'cluster-disks-active', nlabel => 'cluster.disks.active.count', display_ok => 0, set => {
                key_values => [ { name => 'disks_active' }, { name => 'disks_total' }, { name => 'name'} ],
                output_template => 'active %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'disks_total', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{disks} = [
        { label => 'disk-status', type => COUNTER_KIND_TEXT, critical_default => '%{status} !~ /active/', set => {
                key_values => [ { name => 'status' }, { name => 'id' }, { name => 'raid_type' }, { name => 'raid_status' }, { name => 'path' }, { name => 'is_encrypted' } ],
                closure_custom_output => $self->can('custom_status_output'),
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
        %$timerange_filters,
        'filter-disk-id:s'       => { redirect => 'include_disk_id' },
        'include-disk-id:s'      => { name => 'include_disk_id',      default => '' },
        'exclude-disk-id:s'      => { name => 'exclude_disk_id',      default => '' },
        'include-disk-path:s'    => { name => 'include_disk_path',    default => '' },
        'exclude-disk-path:s'    => { name => 'exclude_disk_path',    default => '' }
    });

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

    my $result = $options{custom}->get_cluster_disks( filters => $filters );

    $self->{output}->option_exit(short_msg => "No matching cluster !")
        unless ref $result eq 'ARRAY';

    $self->{clusters} = {};

    foreach my $cluster (@{$result}) {
        my $cluster_id = $cluster->{id} // '';
        my $cluster_name = $cluster->{name} // '';
        next if $options{custom}->is_common_excluded(id => $cluster_id, name => $cluster_name);

        next unless ref $cluster->{clusterDiskConnection} eq 'HASH' && $cluster->{clusterDiskConnection}->{nodes};

        my $cluster_item = {
            name => $cluster_name,
            id => $cluster_id,
            cluster => {
                name => $cluster_name,
                disks_total => 0,
                disks_active => 0
            },
            disks => {}
        };

        foreach my $disk (@{$cluster->{clusterDiskConnection}->{nodes}}) {
            next if is_excluded($disk->{diskId}, $self->{option_results}->{include_disk_id}, $self->{option_results}->{exclude_disk_id}, output => $self->{output}) ||
                    is_excluded($disk->{path}, $self->{option_results}->{include_disk_path}, $self->{option_results}->{exclude_disk_path}, output => $self->{output});
            my $disk_status = lc $disk->{status};

            $cluster_item->{disks}->{ $disk->{diskId} } = {
                id => $disk->{diskId},
                raid_type => $disk->{raidType} // 'none',
                raid_status => lc($disk->{raidStatus}),
                status => $disk_status,
                is_encrypted => $disk->{isEncrypted} ? 'true': 'false',
                path => $disk->{path}
            };

            $cluster_item->{cluster}->{disks_active}++
                if $disk_status eq 'active';

            $cluster_item->{cluster}->{disks_total}++;
        }

        $self->{clusters}->{$cluster_id} = $cluster_item;
    }

    $self->{output}->option_exit(short_msg => "No matching cluster !")
        unless %{$self->{clusters}};
}

1;

__END__

=head1 MODE

Check disks status via GraphQL API.

=over 8

=item B<--start-time>

Set start time for filtering disks by registration date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--end-time>

Set end time for filtering disks by registration date. Accepts ISO 8601 format (C<YYYY-MM-DDTHH:mm:ssZ>), or C<YYYY-MM-DD>, or C<YYYY-MM-DD HH:mm:ss>.

=item B<--last>

Set duration to filter last registered disks. Use 'd' for day, 'h' for hour, 'm' for minute (e.g., C<24h>, C<30m>, C<7d>).

=item B<--include-disk-id>

Include disk ID (can be a regexp).

=item B<--exclude-disk-id>

Exclude disk ID (can be a regexp).

=item B<--include-disk-path>

Include disk path (can be a regexp).

=item B<--exclude-disk-path>

Exclude disk path (can be a regexp).

=item B<--unknown-disk-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{id}, %{path}

=item B<--warning-disk-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{id}, %{path}

=item B<--critical-disk-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /active/').
You can use the following variables: %{status}, %{id}, %{path}

=item B<--warning-cluster-disks-total>

Warning threshold for total number of disks per cluster.

=item B<--critical-cluster-disks-total>

Critical threshold for total number of disks per cluster.

=item B<--warning-cluster-disks-active>

Warning threshold for number of active disks per cluster.

=item B<--critical-cluster-disks-active>

Critical threshold for number of active disks per cluster.

=back

=cut
