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

package storage::stormagic::svsan::snmp::mode::mirrors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_mirror_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s - online: %s",
        $self->{result_values}->{mirror_state},
        $self->{result_values}->{mirror_online}
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

sub mirror_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking mirror '%s'",
        $options{instance_value}->{display}
    );
}

sub prefix_mirror_output {
    my ($self, %options) = @_;

    return sprintf(
        "mirror '%s' ",
        $options{instance_value}->{display}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name               => 'mirror',
            type               => COUNTER_TYPE_MULTIPLE,
            cb_prefix_output   => 'prefix_mirror_output',
            cb_long_output     => 'mirror_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All mirrors are ok',
            group              =>
                [
                    { name => 'status', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { -10 => 1 } },
                    { name => 'mbc', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { -10 => 1 } },
                    { name => 'cache', type => COUNTER_MULTIPLE_INSTANCE, skipped_code => { -10 => 1 } }
                ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'mirror-status',
            type             => COUNTER_KIND_TEXT,
            unknown_default  => '%{mirror_state} =~ /unknown/i',
            warning_default  => '%{mirror_state} =~ /degraded|missing|migrated/i',
            critical_default => '%{mirror_state} =~ /failed|offline/i || %{mirror_online} =~ /no/i',
            set              =>
                {
                    key_values                     => [
                        { name => 'mirror_state' },
                        { name => 'mirror_online' },
                    ],
                    closure_custom_output          => $self->can('custom_mirror_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        { label => 'mirror-size', nlabel => 'mirror.size.bytes', set => {
            key_values          =>
                [ { name => 'size' } ],
            output_template     => 'size: %s %s',
            output_change_bytes => 1,
            perfdatas           =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        },
    ];

    $self->{maps_counters}->{mbc} = [
        { label => 'mbc-usage', nlabel => 'mirror.mbc.usage.bytes', set => {
            key_values            =>
                [
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'size' },
                    { name => 'display' }
                ],
            closure_custom_output =>
                $self->can('custom_space_usage_output'),
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
        { label => 'mbc-usage-free', display_ok => 0, nlabel => 'mirror.mbc.free.bytes', set => {
            key_values            =>
                [
                    { name => 'free' },
                    { name => 'used' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'size' },
                    { name => 'display' }
                ],
            closure_custom_output =>
                $self->can('custom_space_usage_output'),
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
        { label => 'mbc-usage-prct', display_ok => 0, nlabel => 'mirror.mbc.usage.percentage', set => {
            key_values            =>
                [
                    { name => 'prct_used' },
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_free' },
                    { name => 'size' },
                    { name => 'display' }
                ],
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
            critical_default => '%{cache_state} =~ /failed/i',
            set              =>
                {
                    key_values                     => [
                        { name => 'cache_state' }
                    ],
                    closure_custom_output          => $self->can('custom_cache_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        { label => 'cache-size', nlabel => 'mirror.cache.size.bytes', set => {
            key_values          =>
                [ { name => 'size' } ],
            output_template     => 'cache size: %s %s',
            output_change_bytes => 1,
            perfdatas           =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'include-name:s' => { name => 'include_name' },
            'exclude-name:s' => { name => 'exclude_name' }
        });

    return $self;
}

my $map_mirror_state = {
    0 => 'online', 1 => 'offline', 2 => 'degraded', 3 => 'migrated', 4 => 'failed', 5 => 'missing', 6 => 'unknown'
};

my $map_mirror_cache_state = {
    0 => 'unknown', 1 => 'disabled', 2 => 'online', 3 => 'flushing', 4 => 'failed'
};

my $map_online = {
    0 => 'no', 1 => 'yes'
};

my $mapping = {
    mirrorName         => { oid => '.1.3.6.1.4.1.38003.1.4.1.2' },# mirrorName,
    mirrorNSH          => { oid => '.1.3.6.1.4.1.38003.1.4.1.9' },# mirrorNSH,
    mirrorSize         => { oid => '.1.3.6.1.4.1.38003.1.4.1.5' },# mirrorSize,
    mirrorState        => { oid => '.1.3.6.1.4.1.38003.1.4.1.6', map => $map_mirror_state },# mirrorState,
    mirrorOnline       => { oid => '.1.3.6.1.4.1.38003.1.4.1.7', map => $map_online },# mirrorOnline
    mirrorResyncProg   => { oid => '.1.3.6.1.4.1.38003.1.4.1.8' },# mirrorResyncProg,
    mirrorCachePresent => { oid => '.1.3.6.1.4.1.38003.1.4.1.10' },# mirrorCachePresent
    mirrorCacheState   => { oid => '.1.3.6.1.4.1.38003.1.4.1.11', map => $map_mirror_cache_state },# mirrorCacheState
    mirrorCacheSize    => { oid => '.1.3.6.1.4.1.38003.1.4.1.12' },# mirrorCacheSize
    mirrorMBCPresent   => { oid => '.1.3.6.1.4.1.38003.1.4.1.15' },# mirrorMBCPresent
    mirrorMBCLoaded    => { oid => '.1.3.6.1.4.1.38003.1.4.1.16' },# mirrorMBCLoaded
    mirrorMBCSize      => { oid => '.1.3.6.1.4.1.38003.1.4.1.17' },# mirrorMBCSize
    mirrorMBCFree      => { oid => '.1.3.6.1.4.1.38003.1.4.1.18' }# mirrorMBCFree
};

my $oid_mirrorEntry = '.1.3.6.1.4.1.38003.1.4.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_mirrorEntry, nothing_quit => 1);

    foreach my $oid (sort keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{mirrorName}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if is_excluded(
            $result->{mirrorName},
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name}
        );

        $self->{mirror}->{$instance} = {
            display => $result->{mirrorName}
        };

        $self->{mirror}->{$instance}->{status} = {
            mirror_state  => $result->{mirrorState},
            mirror_online => $result->{mirrorOnline},
            size          => $result->{mirrorSize} * 1024 * 1024,
        };

        if ($result->{mirrorMBCPresent} == 1) {
            my $size = defined($result->{mirrorMBCSize}) ? $result->{mirrorMBCSize} * 1024 * 1024 : undef;
            my $free = defined($result->{mirrorMBCFree}) ? $result->{mirrorMBCFree} * 1024 * 1024 : undef;
            my $used = defined($size) && defined($free) ? $size - $free : undef;

            $self->{mirror}->{$instance}->{mbc} = {
                display   => $result->{mirrorName},
                free      => $free,
                size      => $size,
                used      => $used,
                prct_used => defined($size) && $size > 0 ? $used * 100 / $size : undef,
                prct_free => defined($size) && $size > 0 ? $free * 100 / $size : undef
            };
        } else {
            $self->{output}->output_add(long_msg => sprintf("mirror '%s' has no memory cache (MBC)",$result->{mirrorName}));
        }

        if ($result->{mirrorCachePresent} == 1) {
            $self->{mirror}->{$instance}->{cache} = {
                size        => $result->{mirrorCacheSize},
                cache_state => $result->{mirrorCacheState},
            };
        } else {
            $self->{output}->output_add(long_msg => sprintf("mirror '%s' has no cache",$result->{mirrorName}));
        }
    }

    if (scalar(keys %{$self->{mirror}}) <= 0) {
        $self->{output}->option_exit(short_msg => "No mirror matching with filter found.");
    }
}

1;

__END__

=head1 MODE

Check mirrors.

=over 8

=item B<--include-name>

Filter mirrors by name (can be a regexp).

=item B<--exclude-name>

Exclude mirrors by name (can be a regexp).

=item B<--unknown-mirror-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{mirror_state}>, C<%{mirror_online}>, C<%{display}>

=item B<--warning-mirror-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: C<%{mirror_state}>, C<%{mirror_online}>, C<%{display}>

=item B<--critical-mirror-status>

Define the conditions to match for the status to be CRITICAL (default: '%{mirror_state} !~ /normal/i || %{mirror_online} =~ /offline/i').
You can use the following variables: C<%{mirror_state}>, C<%{mirror_online}>, C<%{display}>

=item B<--unknown-cache-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{cache_state} =~ /unknown/i').
You can use the following variables: C<%{cache_state}>, C<%{display}>

=item B<--warning-cache-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: C<%{cache_state}>, C<%{display}>

=item B<--critical-cache-status>

Define the conditions to match for the status to be CRITICAL (default: '%{cache_state} =~ /failed/i').
You can use the following variables: C<%{cache_state}>, C<%{display}>

=item B<--warning-space-usage>

Warning threshold for space usage (B).

=item B<--critical-space-usage>

Critical threshold for space usage (B).

=item B<--warning-space-usage-prct>

Warning threshold for space usage (%).

=item B<--critical-space-usage-prct>

Critical threshold for space usage (%).

=item B<--warning-space-usage-free>

Warning threshold for free space (B).

=item B<--critical-space-usage-free>

Critical threshold for free space (B).

=item B<--warning-mirror-size>

Warning threshold for mirror size (B).

=item B<--critical-mirror-size>

Critical threshold for mirror size (B).

=item B<--warning-cache-size>

Warning threshold for cache size (B).

=item B<--critical-cache-size>

Critical threshold for cache size (B).

=item B<--warning-mbc-usage>

Warning threshold for memory cache usage (B).

=item B<--critical-mbc-usage>

Critical threshold for memory cache usage (B).

=item B<--warning-mbc-usage-free>

Warning threshold for free memory cache (B).

=item B<--critical-mbc-usage-free>

Critical threshold for free memory cache (B).

=item B<--warning-mbc-usage-prct>

Warning threshold for memory cache usage (%).

=item B<--critical-mbc-usage-prct>

Critical threshold for memory cache usage (%).

=back

=cut

