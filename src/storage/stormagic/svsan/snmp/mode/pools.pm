#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package storage::stormagic::svsan::snmp::mode::pools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_pool_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{pool_state}
    );
}

sub custom_cache_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "cache status: %s",
        $self->{result_values}->{cache_state}
    );
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{capacity});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "capacity: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_cache_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{size});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "size: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub pool_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking pool '%s'",
        $options{instance_value}->{display}
    );
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return sprintf(
        "pool '%s' ",
        $options{instance_value}->{display}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name               => 'pool',
            type               => COUNTER_TYPE_MULTIPLE,
            cb_prefix_output   => 'prefix_pool_output',
            cb_long_output     => 'pool_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All pools are ok',
            group              =>
                [
                    { name => 'status', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { -10 => 1 } },
                    { name => 'space', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { -10 => 1 } },
                    { name => 'cache', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { -10 => 1 } }
                ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'pool-status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{pool_state} !~ /normal/i || %{pool_online} =~ /offline/i',
            set              =>
                {
                    key_values                     => [
                        { name => 'pool_state' },
                        { name => 'pool_online' },
                        { name => 'display' }
                    ],
                    closure_custom_output          => $self->can('custom_pool_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        }
    ];

    $self->{maps_counters}->{space} = [
        { label => 'space-usage', nlabel => 'pool.space.usage.bytes', set => {
            key_values            =>
                [ { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'capacity' },
                    { name => 'display' } ],
            closure_custom_output =>
                $self->can('custom_space_usage_output'),
            perfdatas             =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 'capacity',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'pool.space.free.bytes', set => {
            key_values            =>
                [ { name => 'free' },
                    { name => 'used' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'capacity' },
                    { name => 'display' } ],
            closure_custom_output =>
                $self->can('custom_space_usage_output'),
            perfdatas             =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 'capacity',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'pool.space.usage.percentage', set => {
            key_values            =>
                [ { name => 'prct_used' },
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_free' },
                    { name => 'capacity' },
                    { name => 'display' } ],
            closure_custom_output =>
                $self->can('custom_space_usage_output'),
            perfdatas             =>
                [
                    {
                        template             => '%.2f',
                        min                  => 0,
                        max                  => 100,
                        unit                 => '%',
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        }
    ];

    $self->{maps_counters}->{cache} = [
        {
            label            => 'cache-status',
            type             => COUNTER_KIND_TEXT,
            unknown_default  => '%{cache_state} =~ /unknown/i',
            warning_default  => '%{cache_state} =~ /recovering/i',
            critical_default => '%{cache_state} =~ /failed/i',
            set              =>
                {
                    key_values                     => [
                        { name => 'cache_state' },
                        { name => 'display' }
                    ],
                    closure_custom_output          => $self->can('custom_cache_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        { label => 'cache-usage', nlabel => 'pool.cache.usage.bytes', set => {
            key_values            =>
                [ { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'size' },
                    { name => 'display' } ],
            closure_custom_output =>
                $self->can('custom_cache_usage_output'),
            perfdatas             =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 'size',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        },
        { label => 'cache-usage-free', display_ok => 0, nlabel => 'pool.cache.free.bytes', set => {
            key_values            =>
                [ { name => 'free' },
                    { name => 'used' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'size' },
                    { name => 'display' } ],
            closure_custom_output =>
                $self->can('custom_cache_usage_output'),
            perfdatas             =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        max                  => 'size',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        },
        { label => 'cache-usage-prct', display_ok => 0, nlabel => 'pool.cache.usage.percentage', set => {
            key_values            =>
                [ { name => 'prct_used' },
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_free' },
                    { name => 'size' },
                    { name => 'display' } ],
            closure_custom_output =>
                $self->can('custom_cache_usage_output'),
            perfdatas             =>
                [
                    {
                        template             => '%.2f',
                        min                  => 0,
                        max                  => 100,
                        unit                 => '%',
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'include-name:s'  => { name => 'include_name' },
            'exclude-name:s'  => { name => 'exclude_name' },
            'skip-zero-cache' => { name => 'skip_zero_cache' },
        });

    return $self;
}

my $map_cache_state = {
    0 => 'unknown', 1 => 'none', 2 => 'failed', 3 => 'online', 4 => 'flushing', 5 => 'recovering'
};

my $map_online = {
    0 => 'offline', 1 => 'online'
};

my $mapping = {
    poolName       => { oid => '.1.3.6.1.4.1.38003.1.2.1.2' },# poolName,
    poolCapacity   => { oid => '.1.3.6.1.4.1.38003.1.2.1.3' },# poolCapacity,
    poolFreeSpace  => { oid => '.1.3.6.1.4.1.38003.1.2.1.4' },# poolFreeSpace,
    poolState      => { oid => '.1.3.6.1.4.1.38003.1.2.1.5' },# poolState,
    poolOnline     => { oid => '.1.3.6.1.4.1.38003.1.2.1.6', map => $map_online },# poolOnline
    poolCacheState => { oid => '.1.3.6.1.4.1.38003.1.2.1.7', map => $map_cache_state },# poolCacheState
    poolCacheSize  => { oid => '.1.3.6.1.4.1.38003.1.2.1.8' },# poolCacheSize,
    poolCacheFree  => { oid => '.1.3.6.1.4.1.38003.1.2.1.9' }# poolCacheFree
};

my $oid_poolEntry = '.1.3.6.1.4.1.38003.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_poolEntry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{poolName}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if is_excluded(
            $result->{poolName},
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name}
        );

        $self->{pool}->{$instance} = {
            display => $result->{poolName}
        };

        $self->{pool}->{$instance}->{status} = {
            display     => $result->{poolName},
            pool_state  => $result->{poolState},
            pool_online => $result->{poolOnline},
        };

        my $free = defined($result->{poolFreeSpace}) ? $result->{poolFreeSpace} * 1024 * 1024 : undef;
        my $capacity = defined($result->{poolCapacity}) ? $result->{poolCapacity} * 1024 * 1024 : undef;
        my $used = defined($capacity) && defined($free) ? $capacity - $free : 0;

        $self->{pool}->{$instance}->{space} = {
            display   => $result->{poolName},
            free      => $free,
            capacity  => $capacity,
            used      => $used,
            prct_used => defined($capacity) && $capacity > 0 ? $free * 100 / $capacity : undef,
            prct_free => defined($capacity) && $capacity > 0 ? $used * 100 / $capacity : undef,
        };

        if (defined($self->{option_results}->{skip_zero_cache})
            && (!defined($result->{poolCacheSize}) || $result->{poolCacheSize} == 0)) {
            $self->{output}->output_add(long_msg => sprintf("pool '%s' has no cache", $result->{poolName}));
        } else {
            $free = defined($result->{poolCacheFree}) ? $result->{poolCacheFree} * 1024 * 1024 : undef;
            my $size = $result->{poolCacheSize} * 1024 * 1024;
            $used = defined($size) && defined($free) ? $size - $free : 0;

            $self->{pool}->{$instance}->{cache} = {
                display     => $result->{poolName},
                cache_state => $result->{poolCacheState},
                free        => $free,
                size        => $size,
                used        => $used,
                prct_used   => defined($size) && $size > 0 ? $free * 100 / $size : undef,
                prct_free   => defined($size) && $size > 0 ? $used * 100 / $size : undef,
            }
        }
    }

    if (scalar(keys %{$self->{pool}}) <= 0) {
        $self->{output}->option_exit(short_msg => "No pool matching with filter found.");
    }
}

1;

__END__

=head1 MODE

Check pools.

=over 8

=item B<--include-name>

Filter pools by name (can be a regexp).

=item B<--exclude-name>

Exclude pools by name (can be a regexp).

=item B<--skip-zero-cache>

Skip cache that have zero size.

=item B<--unknown-pool-status>

Define the conditions to match for the status to be UNKNOWN (default: '').
You can use the following variables: %{status}, %{display}

=item B<--warning-pool-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{status}, %{display}

=item B<--critical-pool-status>

Define the conditions to match for the status to be CRITICAL (default: '%{pool_state} !~ /normal/i || %{pool_online} =~ /offline/i').
You can use the following variables: %{status}, %{display}

=item B<--unknown-cache-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{cache_state} =~ /unknown/i').
You can use the following variables: %{cache_state}, %{display}

=item B<--warning-cache-status>

Define the conditions to match for the status to be WARNING (default: '%{cache_state} =~ /recovering/i').
You can use the following variables: %{cache_state}, %{display}

=item B<--critical-cache-status>

Define the conditions to match for the status to be CRITICAL (default: '%{cache_state} =~ /failed/i').
You can use the following variables: %{cache_state}, %{display}

=item B<--warning-space-usage>

Threshold for warning when the space usage exceeds the specified value in bytes.

=item B<--critical-space-usage>

Threshold for critical when the space usage exceeds the specified value in bytes.

=item B<--warning-space-usage-prct>

Threshold for warning when the space usage exceeds the specified percentage of the total capacity.

=item B<--critical-space-usage-prct>

Threshold for critical when the space usage exceeds the specified percentage of the total capacity.

=item B<--warning-space-usage-free>

Threshold for warning when the free space falls below the specified value in bytes.

=item B<--critical-space-usage-free>

Threshold for critical when the free space falls below the specified value in bytes.

=back

=cut

