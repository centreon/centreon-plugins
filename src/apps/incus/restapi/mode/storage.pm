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

package apps::incus::restapi::mode::storage;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters :values);

# GET /1.0/storage-pools/{name}/resources metadata, shortened:
# {"space":{"used":343537419776,"total":420100937728},"inodes":{"used":23937695,"total":30709993797}}
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml

sub pool_percent {
    my ($used, $total) = @_;

    return undef if (!defined($total) || $total <= 0 || !defined($used));
    return ($used / $total) * 100;
}

sub pool_usage {
    my ($resources) = @_;

    $resources = {} if (ref($resources) ne 'HASH');
    my $space = (ref($resources->{space}) eq 'HASH') ? $resources->{space} : {};
    my $inodes = (ref($resources->{inodes}) eq 'HASH') ? $resources->{inodes} : {};
    return {
        space_used => $space->{used},
        space_total => $space->{total},
        space_prct => pool_percent($space->{used}, $space->{total}),
        inodes_used => $inodes->{used},
        inodes_total => $inodes->{total},
        inodes_prct => pool_percent($inodes->{used}, $inodes->{total})
    };
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'summary', type => COUNTER_TYPE_GLOBAL, prefix_output => 'storage ' },
        { name => 'pool', type => COUNTER_TYPE_INSTANCE, prefix_output => "pool '%{display}' ", message_multiple => 'all storage pools are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{summary} = [
        { label => 'pools', nlabel => 'incus.storage.pools.count', set => {
                key_values => [ { name => 'pools' } ],
                output_template => 'pools: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{pool} = [
        { label => 'space', nlabel => 'incus.storage.space.usage.bytes', set => {
                key_values => [ { name => 'space_used' }, { name => 'display' } ],
                output_template => 'space used: %s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'space-prct', nlabel => 'incus.storage.space.usage.percentage', set => {
                key_values => [ { name => 'space_prct' }, { name => 'display' } ],
                output_template => 'space: %.2f %%',
                output_use => 'space_prct',
                perfdatas => [ { value => 'space_prct', template => '%.2f', min => 0, unit => '%', label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'inodes', nlabel => 'incus.storage.inodes.usage.count', set => {
                key_values => [ { name => 'inodes_used' }, { name => 'display' } ],
                output_template => 'inodes used: %s',
                perfdatas => [ { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'inodes-prct', nlabel => 'incus.storage.inodes.usage.percentage', set => {
                key_values => [ { name => 'inodes_prct' }, { name => 'display' } ],
                output_template => 'inodes: %.2f %%',
                output_use => 'inodes_prct',
                perfdatas => [ { value => 'inodes_prct', template => '%.2f', min => 0, unit => '%', label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
    ];
}

# A missing used or total must not be stored as undef: the counter would
# then call threshold_check on an empty value.
sub _defined_fields {
    my ($usage, $display) = @_;

    my %entry = (display => $display);
    foreach my $field (qw(space_used space_prct inodes_used inodes_prct)) {
        $entry{$field} = $usage->{$field} if (defined($usage->{$field}));
    }
    return \%entry;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metadata = $options{custom}->storage_pools();
    my $pools = $options{custom}->filter_records(records => $metadata, name_key => 'name');
    $self->{summary} = { pools => scalar(@$pools) };
    $self->{pool} = {};
    foreach my $pool (@$pools) {
        my $name = defined($pool->{name}) ? $pool->{name} : '';
        my $resources = $options{custom}->storage_pool_resources(name => $name);
        my $usage = pool_usage($resources);
        $self->{pool}->{$name} = _defined_fields($usage, $name);
    }
}

1;

__END__

=head1 MODE

Check storage pool space and inodes.

GET /1.0/storage-pools?recursion=1, then GET /1.0/storage-pools/{name}/resources
for each pool. The pool name is percent-encoded. A percentage is published only
when total is greater than 0. Thresholds are empty by default.

=over 8

=item B<--warning-pools>

Warning threshold for the number of storage pools.

=item B<--critical-pools>

Critical threshold for the number of storage pools.

=item B<--warning-space>

Warning threshold for the used space of a pool, in bytes.

=item B<--critical-space>

Critical threshold for the used space of a pool, in bytes.

=item B<--warning-space-prct>

Warning threshold for the used space of a pool, in percent.

=item B<--critical-space-prct>

Critical threshold for the used space of a pool, in percent.

=item B<--warning-inodes>

Warning threshold for the number of used inodes of a pool.

=item B<--critical-inodes>

Critical threshold for the number of used inodes of a pool.

=item B<--warning-inodes-prct>

Warning threshold for the used inodes of a pool, in percent.

=item B<--critical-inodes-prct>

Critical threshold for the used inodes of a pool, in percent.

=back

=cut
