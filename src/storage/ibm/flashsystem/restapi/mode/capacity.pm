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
# Authors : Valentin MAROT <contact@valentin-marot.fr>
#

#
# How full the system is.
#
# Central trap: on a system fitted with FlashCore Modules, a pool's capacity is
# a VIRTUAL, over-allocated view laid over the hardware. A pool can announce
# 630 TB free while 164 TB remain physically out of 311. Putting the alert
# threshold on the pool's free space therefore watches a number unrelated to
# the moment the array fills up.
#
# The threshold therefore belongs on physical_free_capacity, reported by
# lssystem. Pool figures stay published as metrics, for the trend and for the
# over-allocation ratio, but trigger nothing by themselves.
#

package storage::ibm::flashsystem::restapi::mode::capacity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_pool_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s, overallocation: %s%%, data reduction: %s',
        $self->{result_values}->{status},
        $self->{result_values}->{overallocation},
        $self->{result_values}->{data_reduction}
    );
}

sub prefix_physical_output {
    my ($self, %options) = @_;

    return 'Physical capacity: ';
}

sub prefix_logical_output {
    my ($self, %options) = @_;

    return 'Logical: ';
}

sub prefix_reduction_output {
    my ($self, %options) = @_;

    return 'Data reduction: ';
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return "Pool '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'physical', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_physical_output' },
        { name => 'logical', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_logical_output' },
        { name => 'reduction', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_reduction_output',
          skipped_code => { NO_VALUE() => 1 } },
        { name => 'pools', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_pool_output',
          message_multiple => 'All pools are online', skipped_code => { NO_VALUE() => 1 } }
    ];

    # This is the counter that carries the alert. No default is shipped: the
    # right value depends on how long an extension takes to be delivered, not
    # on a general rule.
    $self->{maps_counters}->{physical} = [
        { label => 'physical-usage-prct', nlabel => 'system.physical.space.usage.percentage',
          set => {
                key_values => [ { name => 'physical_used_prct' } ],
                output_template => 'used %.2f %%',
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100 } ]
            }
        },
        # output_change_bytes converts the value AND returns the unit: the template
        # must carry TWO %s. With one, the unit is lost and the output reads
        # "used 146.45" without saying of what.
        { label => 'physical-usage', nlabel => 'system.physical.space.usage.bytes', set => {
                key_values => [ { name => 'physical_used' }, { name => 'physical_total' } ],
                output_template => '%s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%d', unit => 'B', min => 0, max => 'physical_total' } ]
            }
        },
        { label => 'physical-free', nlabel => 'system.physical.space.free.bytes', set => {
                key_values => [ { name => 'physical_free' }, { name => 'physical_total' } ],
                output_template => 'free %s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%d', unit => 'B', min => 0, max => 'physical_total' } ]
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
                key_values => [ { name => 'logical_used' } ],
                output_template => 'used %s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%d', unit => 'B', min => 0 } ]
            }
        },
        { label => 'logical-free', nlabel => 'system.logical.space.free.bytes', set => {
                key_values => [ { name => 'logical_free' } ],
                output_template => 'free %s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%d', unit => 'B', min => 0 } ]
            }
        }
    ];

    # What data reduction saves. The ratio speaks better than bytes: "2.40:1"
    # compares from one array to another and from one month to the next,
    # "12 TB" does not.
    #
    # These two counters live in a SEPARATE group, of type 1, for a precise
    # reason: a type 0 counter whose value is missing is not silent, it prints
    # "skipped (no value(s))". When no pool enables reduction - a common case -
    # that put two skip mentions in an otherwise normal output, which read like
    # a fault. An empty type 1 group prints nothing at all.
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
                closure_custom_output => $self->can('custom_pool_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'pool-usage-prct', nlabel => 'pool.space.usage.percentage', set => {
                key_values => [ { name => 'used_prct' }, { name => 'name' } ],
                output_template => 'used %.2f %%',
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100,
                                 label_extra_instance => 1, instance_use => 'name' } ]
            }
        },
        { label => 'pool-free', nlabel => 'pool.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'name' } ],
                output_template => 'free %s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%d', unit => 'B', min => 0,
                                 label_extra_instance => 1, instance_use => 'name' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-pool:s' => { name => 'filter_pool' }
    });

    return $self;
}

sub field {
    my ($entry, $name) = @_;

    return '-' if (!defined($entry->{$name}) || $entry->{$name} eq '');
    return $entry->{$name};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $system = $options{custom}->request(command => 'lssystem')->[0];

    my $physical_total = $options{custom}->size_to_bytes(value => $system->{physical_capacity});
    my $physical_free = $options{custom}->size_to_bytes(value => $system->{physical_free_capacity});

    # Without physical capacity we are probably on a model without FlashCore
    # Modules. Rather than making a figure up, say so and stick to the pools,
    # whose thresholds remain usable.
    if (!defined($physical_total) || !defined($physical_free) || $physical_total == 0) {
        $self->{output}->output_add(
            long_msg => 'System reports no physical capacity: thresholds on pools only.',
            severity => 'OK'
        );
        $self->{physical} = {};
    } else {
        my $physical_used = $physical_total - $physical_free;
        $self->{physical} = {
            physical_total => $physical_total,
            physical_free => $physical_free,
            physical_used => $physical_used,
            physical_used_prct => $physical_used * 100 / $physical_total,
            overallocation => field($system, 'total_overallocation')
        };
    }

    $self->{logical} = {
        logical_used => $options{custom}->size_to_bytes(value => $system->{total_used_capacity}),
        logical_free => $options{custom}->size_to_bytes(value => $system->{total_free_space})
    };

    # Reduction ratio: what was written over what is really stored. Both
    # counters are 0 when no pool enables data reduction - then neither ratio
    # nor saving is published, rather than showing a misleading 1:1.
    my $before = $options{custom}->size_to_bytes(value => $system->{used_capacity_before_reduction});
    my $after = $options{custom}->size_to_bytes(value => $system->{used_capacity_after_reduction});

    # Data reduction can happen at TWO layers, published by different fields:
    #
    #   - the software layer (Data Reduction Pools): the
    #     used_capacity_before/after_reduction counters of lssystem. They are 0
    #     as soon as the pools are in data_reduction=no.
    #   - the HARDWARE compression of the FlashCore Modules, one layer below,
    #     in the drives. It ONLY shows in the detailed view of the mdisks
    #     (effective_used_capacity = written before compression, against the
    #     physical capacity really consumed). It is what the GUI calls "Data
    #     reduction" on such systems: 265.45/146.45 = 1.81:1 on a surveyed
    #     FlashSystem 5300, verified to the decimal against the display.
    #
    # The active layer is published, and named in the long output.
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
        foreach my $mdisk (@{ $options{custom}->request_optional(command => 'lsmdisk') }) {
            next unless (ref $mdisk eq 'HASH' && defined($mdisk->{id}) && $mdisk->{id} =~ /^\d+$/);
            # The concise view carries none of these fields: the detailed view is
            # needed, one call per mdisk. There are one or two per array.
            my $detail = $options{custom}->request_optional(command => 'lsmdisk/' . $mdisk->{id})->[0];
            next unless (ref $detail eq 'HASH');

            my $eff   = $options{custom}->size_to_bytes(value => $detail->{effective_used_capacity});
            my $ptot  = $options{custom}->size_to_bytes(value => $detail->{physical_capacity});
            my $pfree = $options{custom}->size_to_bytes(value => $detail->{physical_free_capacity});
            # An mdisk without physical capacity is not backed by FCMs (classic
            # drives): it compresses nothing.
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
            # Say it once, in the long output, rather than letting two empty
            # counters clutter the summary line.
            $self->{output}->output_add(
                long_msg => 'No data reduction active at any layer: no ratio to report.'
            );
        }
    }

    $self->{pools} = {};
    foreach my $pool (@{ $options{custom}->request(command => 'lsmdiskgrp') }) {
        my $name = field($pool, 'name');
        next if (defined($self->{option_results}->{filter_pool}) && $self->{option_results}->{filter_pool} ne ''
            && $name !~ /$self->{option_results}->{filter_pool}/);

        my $capacity = $options{custom}->size_to_bytes(value => $pool->{capacity});
        my $free = $options{custom}->size_to_bytes(value => $pool->{free_capacity});

        $self->{pools}->{$name} = {
            name => $name,
            status => field($pool, 'status'),
            overallocation => field($pool, 'overallocation'),
            data_reduction => field($pool, 'data_reduction'),
            free => $free,
            used_prct => (defined($capacity) && defined($free) && $capacity > 0)
                ? ($capacity - $free) * 100 / $capacity
                : undef
        };
    }
}

1;

__END__

=head1 MODE

Check how full the system is.

On a system fitted with FlashCore Modules, a pool's capacity is a B<virtual>,
over-allocated view of the hardware: a pool can report 630 TB free while only
164 TB of 311 remain physically. A threshold on the pool's free space therefore
watches a number unrelated to the moment the array fills up.

Thresholds are meant to be set on B<physical-usage-prct>, taken from
C<lssystem>. Pool figures are still published as metrics — for the trend and for
the over-allocation ratio — but only the pool B<status> alerts on its own.

The data reduction ratio is read from whichever layer actually reduces:
the software layer (data reduction pools, C<used_capacity_*_reduction>) when a
pool enables it, otherwise the B<FlashCore Module hardware compression>, which
only the detailed per-mdisk view exposes (C<effective_used_capacity> — written
by hosts — against the physical capacity actually consumed). The long output
names the layer being measured. This matches the GUI's "Data reduction" figure;
the GUI's larger "Total savings" ratio additionally counts thin provisioning
and is deliberately not reproduced — over-allocation is already published as
its own metric.

Example:

    perl centreon_plugins.pl --plugin=storage::ibm::flashsystem::restapi::plugin \
        --mode=capacity --hostname=10.0.0.1 \
        --api-username=svc_monitor --api-password=xxx --insecure \
        --warning-physical-usage-prct=75 --critical-physical-usage-prct=85

=over 8

=item B<--filter-pool>

Only check pools whose name matches this regular expression.

=item B<--warning-physical-usage-prct> B<--critical-physical-usage-prct>

Thresholds on the percentage of B<physical> capacity used. This is the one to
set. No default is shipped: the right value depends on how long it takes to get
an extension delivered, not on a general rule.

=item B<--warning-physical-free> B<--critical-physical-free>

Thresholds on the physical space left, in bytes. Useful when the answer is "we
need N TB of headroom" rather than a percentage.

=item B<--warning-overallocation> B<--critical-overallocation>

Threshold on the over-allocation ratio, in percent.

=item B<--unknown-pool-status> B<--warning-pool-status> B<--critical-pool-status>

Threshold on each pool. Available macros: C<name>, C<status>,
C<overallocation>, C<data_reduction>.

Default critical: C<%{status} !~ /^online$/i>

=item B<--warning-pool-usage-prct> B<--critical-pool-usage-prct> B<--warning-pool-free> B<--critical-pool-free>

Thresholds per pool. Remember these are virtual figures on a FlashCore Module
system.

=back

=cut
