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

package storage::ibm::flashsystem::restapi::mode::capacity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(convert_bytes is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_value . ' ' . $total_unit,
        $used_value . ' ' . $used_unit, $self->{result_values}->{prct_used},
        $free_value . ' ' . $free_unit, $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'physical', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Physical space ' },
        { name => 'logical', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Logical space ' },
        { name => 'reduction', type => COUNTER_TYPE_INSTANCE, prefix_output => 'Data reduction: ',
          skipped_code => { NO_VALUE() => 1 } },
        { name => 'pools', type => COUNTER_TYPE_INSTANCE, prefix_output => "Pool '%{name}' ",
          message_multiple => 'All pools are online', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{physical} = [
        { label => 'physical-usage', nlabel => 'system.physical.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%d', unit => 'B', min => 0, max => 'total' } ]
            }
        },
        { label => 'physical-usage-free', nlabel => 'system.physical.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%d', unit => 'B', min => 0, max => 'total' } ]
            }
        },
        { label => 'physical-usage-prct', nlabel => 'system.physical.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100 } ]
            }
        },
        { label => 'overallocation', nlabel => 'system.space.overallocation.percentage', set => {
                key_values => [ { name => 'overallocation' } ],
                output_template => 'overallocation %s %%',
                perfdatas => [ { template => '%s', unit => '%', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{logical} = [
        { label => 'logical-usage', nlabel => 'system.logical.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%d', unit => 'B', min => 0, max => 'total' } ]
            }
        },
        { label => 'logical-usage-free', nlabel => 'system.logical.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%d', unit => 'B', min => 0, max => 'total' } ]
            }
        },
        { label => 'logical-usage-prct', nlabel => 'system.logical.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100 } ]
            }
        }
    ];

    $self->{maps_counters}->{reduction} = [
        { label => 'data-reduction-ratio', nlabel => 'system.data.reduction.ratio.count', set => {
                key_values => [ { name => 'reduction_ratio' } ],
                output_template => '%.2f:1',
                perfdatas => [ { template => '%.2f', min => 0 } ]
            }
        },
        { label => 'data-reduction-saved', nlabel => 'system.data.reduction.saved.bytes', set => {
                key_values => [ { name => 'reduction_saved' } ],
                output_template => 'saved %s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%d', unit => 'B', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{pools} = [
        {
            label => 'pool-status',
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} !~ /^online$/i',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'status' },
                    { name => 'overallocation' }, { name => 'data_reduction' }
                ],
                output_template => 'status: %{status}, overallocation: %{overallocation}%%, data reduction: %{data_reduction}',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'pool-usage', nlabel => 'pool.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%d', unit => 'B', min => 0, max => 'total', label_extra_instance => 1, instance_use => 'name' } ]
            }
        },
        { label => 'pool-usage-free', nlabel => 'pool.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%d', unit => 'B', min => 0, max => 'total', label_extra_instance => 1, instance_use => 'name' } ]
            }
        },
        { label => 'pool-usage-prct', nlabel => 'pool.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-pool:s' => { name => 'include_pool' },
        'exclude-pool:s' => { name => 'exclude_pool' }
    });

    return $self;
}

sub usage {
    my ($self, %options) = @_;

    return {} if (!defined($options{total}) || !defined($options{free}) || $options{total} == 0);

    my ($total, $free) = (int($options{total}), int($options{free}));
    my $used = $total - $free;
    return {
        total => $total,
        used => $used,
        free => $free,
        prct_used => $used * 100 / $total,
        prct_free => $free * 100 / $total
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $to_bytes = sub { # base 1024 unit-suffixed strings ("310.99TB").
        return convert_bytes(value => $_[0] // '', pattern => '^\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGTP]?B?)\s*$');
    };

    my $system = $options{custom}->request(command => 'lssystem')->[0];

    $self->{physical} = $self->usage(
        total => $to_bytes->($system->{physical_capacity}),
        free => $to_bytes->($system->{physical_free_capacity})
    );
    if (!defined($self->{physical}->{total})) {
        $self->{output}->output_add(long_msg => 'System reports no physical capacity: thresholds on pools only.');
    } elsif (is_not_empty($system->{total_overallocation})) {
        $self->{physical}->{overallocation} = $system->{total_overallocation};
    }

    $self->{logical} = $self->usage(
        total => $to_bytes->($system->{space_in_mdisk_grps}),
        free => $to_bytes->($system->{total_free_space})
    );

    my $before = $to_bytes->($system->{used_capacity_before_reduction});
    my $after = $to_bytes->($system->{used_capacity_after_reduction});

    $self->{reduction} = {};
    if (defined($before) && defined($after) && $after > 0) {
        $self->{reduction}->{system} = {
            reduction_ratio => $before / $after,
            reduction_saved => $before - $after
        };
        $self->{output}->output_add(
            long_msg => 'Data reduction measured at the pool layer (data reduction pools).'
        );
    } else {
        my ($effective, $used) = (0, 0);
        foreach my $mdisk (@{$options{custom}->request_optional(command => 'lsmdisk')}) {
            next if (ref($mdisk) ne 'HASH' || !defined($mdisk->{id}) || $mdisk->{id} !~ /^\d+$/);
            my $detail = $options{custom}->request_optional(command => 'lsmdisk/' . $mdisk->{id})->[0];
            next if (ref($detail) ne 'HASH');

            my $eff = $to_bytes->($detail->{effective_used_capacity});
            my $ptot = $to_bytes->($detail->{physical_capacity});
            my $pfree = $to_bytes->($detail->{physical_free_capacity});
            next if (!defined($eff) || !defined($ptot) || !defined($pfree) || $ptot == 0);

            $effective += $eff;
            $used += $ptot - $pfree;
        }

        if ($used > 0 && $effective > 0) {
            $self->{reduction}->{system} = {
                reduction_ratio => $effective / $used,
                reduction_saved => $effective - $used
            };
            $self->{output}->output_add(
                long_msg => 'Data reduction measured at the drive layer (FlashCore Module compression).'
            );
        } else {
            $self->{output}->output_add(
                long_msg => 'No data reduction active at any layer: no ratio to report.'
            );
        }
    }

    $self->{pools} = {};
    foreach my $pool (@{$options{custom}->request(command => 'lsmdiskgrp')}) {
        my $name = $pool->{name} // '';
        next if (is_excluded($name, $self->{option_results}->{include_pool}, $self->{option_results}->{exclude_pool}));

        $self->{pools}->{$name} = {
            %{$self->usage(total => $to_bytes->($pool->{capacity}), free => $to_bytes->($pool->{free_capacity}))},
            name => $name,
            status => $pool->{status} // '',
            overallocation => $pool->{overallocation} // '',
            data_reduction => $pool->{data_reduction} // ''
        };
    }
}

1;

__END__

=head1 MODE

Check space usage: physical space of the system, logical space and storage pools.

On systems with FlashCore Modules, the logical space is over-allocated: thresholds are meant to be set on the physical space.

=over 8

=item B<--include-pool>

Filter pools by name (can be a regexp).

=item B<--exclude-pool>

Exclude pools by name (can be a regexp).

=item B<--warning-pool-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{name}>, C<%{overallocation}>, C<%{data_reduction}>

=item B<--critical-pool-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} !~ /^online$/i'>).
You can use the following variables: C<%{status}>, C<%{name}>, C<%{overallocation}>, C<%{data_reduction}>

=item B<--unknown-pool-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{status}>, C<%{name}>, C<%{overallocation}>, C<%{data_reduction}>

=item B<--warning-physical-usage>

Threshold in bytes.

=item B<--critical-physical-usage>

Threshold in bytes.

=item B<--warning-physical-usage-free>

Threshold in bytes.

=item B<--critical-physical-usage-free>

Threshold in bytes.

=item B<--warning-physical-usage-prct>

Threshold in percentage.

=item B<--critical-physical-usage-prct>

Threshold in percentage.

=item B<--warning-overallocation>

Threshold in percentage.

=item B<--critical-overallocation>

Threshold in percentage.

=item B<--warning-logical-usage>

Threshold in bytes.

=item B<--critical-logical-usage>

Threshold in bytes.

=item B<--warning-logical-usage-free>

Threshold in bytes.

=item B<--critical-logical-usage-free>

Threshold in bytes.

=item B<--warning-logical-usage-prct>

Threshold in percentage.

=item B<--critical-logical-usage-prct>

Threshold in percentage.

=item B<--warning-data-reduction-ratio>

Threshold.

=item B<--critical-data-reduction-ratio>

Threshold.

=item B<--warning-data-reduction-saved>

Threshold in bytes.

=item B<--critical-data-reduction-saved>

Threshold in bytes.

=item B<--warning-pool-usage>

Threshold in bytes.

=item B<--critical-pool-usage>

Threshold in bytes.

=item B<--warning-pool-usage-free>

Threshold in bytes.

=item B<--critical-pool-usage-free>

Threshold in bytes.

=item B<--warning-pool-usage-prct>

Threshold in percentage.

=item B<--critical-pool-usage-prct>

Threshold in percentage.

=back

=cut
