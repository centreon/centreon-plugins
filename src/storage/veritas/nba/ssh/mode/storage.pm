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

package storage::veritas::nba::ssh::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc;

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub partition_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking partition '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return sprintf(
        "partition '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name               => 'partitions',
            type               => COUNTER_TYPE_MULTIPLE,
            cb_prefix_output   => 'prefix_partition_output',
            cb_long_output     => 'partition_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All partitions are ok',
            group              =>
                [
                    { name => 'partition_status', type => COUNTER_MULTIPLE_INSTANCE },
                    { name => 'partition_space', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { NO_VALUE => 1 } }
                ]
        }
    ];

    $self->{maps_counters}->{partition_space} = [
        {
            label => 'partition-space-usage', nlabel => 'partition.space.usage.bytes', set => {
            key_values            =>
                [
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'total' }
                ],
            closure_custom_output => $self->can('custom_space_usage_output'),
            perfdatas             =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 'total',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1
                    }
                ]
        }
        },
        {
            label => 'partition-space-usage-free', nlabel => 'partition.space.free.bytes', display_ok => 0, set => {
            key_values            =>
                [
                    { name => 'free' },
                    { name => 'used' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'total' }
                ],
            closure_custom_output => $self->can('custom_space_usage_output'),
            perfdatas             =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 'total',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1
                    }
                ]
        }
        },
        {
            label => 'partition-space-usage-prct', nlabel => 'partition.space.usage.percentage', display_ok => 0, set => {
            key_values            =>
                [
                    { name => 'prct_used' },
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_free' },
                    { name => 'total' }
                ],
            closure_custom_output => $self->can('custom_space_usage_output'),
            perfdatas             =>
                [
                    {
                        template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1
                    }
                ]
        }
        }
    ];
 
    $self->{maps_counters}->{partition_status} = [
        {
            label => 'partition-status', type => COUNTER_KIND_TEXT, warning_default => '%{status} =~ /Degraded/i', critical_default => '%{status} =~ /Not Accessible/i', set => {
            key_values                     =>
                [
                    { name => 'status' },
                    { name => 'partitionName' }
                ],
            closure_custom_output          =>  $self->can('custom_status_output'),
            closure_custom_perfdata        => sub { return 0; },
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
        'include-partition-name:s'  => { name => 'include_partition_name',  default => '' },
        'exclude-partition-name:s'  => { name => 'exclude_partition_name',  default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->execute_scenario(
        request => {
            interactive => 1,
            pty => {
                rows => 800,
                cols => 80
            },
            scenario => [
                { "cmd" => "waitfor", "options" => { "Match" =>  'Main_Menu>', "Timeout" => "30" } },
                { "cmd" => "put", "options" => { "String" => "Manage\n", "Timeout" => "5" } },
                { "cmd" => "waitfor", "options" => { "Match" =>  'Manage>', "Timeout" => "5" } },
                { "cmd" => "put", "options" => { "String" => "Storage\n", "Timeout" => "5" } },
                { "cmd" => "waitfor", "options" => { "Match" =>  'Storage>', "Timeout" => "5" } },
                { "cmd" => "put", "options" => { "String" => "Show ALL\n", "Timeout" => "5" } },
                { "cmd" => "waitfor", "options" => { "Match" =>  'to quit|Waiting for data', "Timeout" => "20" } },
                { "cmd" => "close" }
            ]
        }
    );

    #-------------------------------------------------------------------------------
    #Partition      | Total      | Available  | Used       | %Used | Status        
    #-------------------------------------------------------------------------------
    #AdvancedDisk   | 0 GB       | 0 GB       | 0 GB       | 0     | Not Configured
    #CDPGateway     | 0 GB       | 0 GB       | 0 GB       | 0     | Not Configured
    #Configuration  | 100 GB     | 98.64 GB   | 1.36 GB    | 2     | Optimal
    #MSDP           | 251 TB     | 80.49 TB   | 170.51 TB  | 68    | Optimal
    #MSDP Catalog   | 798 GB     | 788.75 GB  | 9.25 GB    | 2     | Optimal
    #NDMP Log       | 750 GB     | 634.58 GB  | 115.42 GB  | 16    | Optimal
    #Share          | 0 GB       | 0 GB       | 0 GB       | 0     | Not Configured
    #Unallocated    | 18.44 TB   | -          | -          | -     | -    

    while ($result =~ /^(.*?)\|.*?\|(.*?)\|(.*?)\|.*?\|\s+(Optimal|Degraded|Not\s+Accessible|Not\s+Configured)/mig) {
        my ($part_name, $part_available, $part_used, $part_status) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($3), $4);

        next if (centreon::plugins::misc::is_excluded($part_name, $self->{option_results}->{include_partition_name}, $self->{option_results}->{exclude_partition_name}));
 
        $self->{partitions}->{$part_name} = {
            name              => $part_name,
            partition_status => {
                partitionName => $part_name,
                status        => $part_status
            }
        };

        $part_used =~ /^(\S+)\s+(\S+)/;
        my $part_used_bytes = centreon::plugins::misc::convert_bytes(value => $1, unit => $2);
        $part_available =~ /^(\S+)\s+(\S+)/;
        my $part_available_bytes = centreon::plugins::misc::convert_bytes(value => $1, unit => $2);
        if (($part_used_bytes + $part_available_bytes) > 0) {
            my $total = $part_used_bytes + $part_available_bytes;
            $self->{partitions}->{$part_name}->{partition_space} = {
                total       => $total,
                free        => $part_available_bytes,
                used        => $part_used_bytes,
                prct_used   => ($part_used_bytes * 100) / $total,
                prct_free   => ($part_available_bytes * 100) / $total
            };
        }
    }

    if (scalar(keys %{$self->{partitions}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get partition information");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storages.

=over 8

=item B<--filter-counters>

Define which counters (filtered by regular expression) should be monitored.
Can be : partition-space-usage partition-space-usage-free partition-space-usage-prct
Example: --filter-counters='partition-status'

=item B<--include-partition-name>

Include partition names (regexp).

=item B<--exclude-partition-name>

Exclude partition names (regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /Degraded/i'>).
You can use the following variables: C<%{status}>, C<%{partitionName}>

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /Not Accessible/i'>).
You can use the following variables: C<%{status}>, C<%{partitionName}>

=item B<--warning-partition-space-usage>

Warning threshold for partition space usage in bytes.

=item B<--critical-partition-space-usage>

Critical threshold for partition space usage in bytes.

=item B<--warning-partition-space-usage-free>

Warning threshold for partition free space usage in bytes.

=item B<--critical-partition-space-usage-free>

Critical threshold for partition free space usage in bytes.

=item B<--warning-partition-space-usage-prct>

Warning threshold for partition space usage in percent.

=item B<--critical-partition-space-usage-prct>

Critical threshold for partition space usage in percent.

=back

=cut
