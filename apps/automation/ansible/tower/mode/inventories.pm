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

package apps::automation::ansible::tower::mode::inventories;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output_global {
    my ($self, %options) = @_;

    return 'Inventories ';
}

sub prefix_output_inventories {
    my ($self, %options) = @_;

    return "Inventory '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output_global' },
        { name => 'inventories', type => 1, cb_prefix_output => 'prefix_output_inventories', message_multiple => 'All inventories are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'inventories.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'failed', nlabel => 'inventories.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'total' } ],
                output_template => 'failed: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{inventories} = [
        { label => 'hosts-total', nlabel => 'inventory.hosts.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total_hosts' }, { name => 'display' } ],
                output_template => 'hosts total: %d',
                perfdatas => [
                    { value => 'total_hosts', template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'hosts-failed', nlabel => 'inventory.hosts.failed.count', set => {
                key_values => [
                    { name => 'hosts_with_active_failures' }, { name => 'total_hosts' }, 
                    { name => 'display' }
                ],
                output_template => 'hosts failed: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_hosts', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'sources-total', nlabel => 'inventory.sources.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total_inventory_sources' }, { name => 'display' } ],
                output_template => 'sources total: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'sources-failed', nlabel => 'inventory.sources.failed.count', set => {
                key_values => [
                    { name => 'inventory_sources_with_failures' }, { name => 'total_inventory_sources' }, 
                    { name => 'display' }
                ],
                output_template => 'sources failed: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_inventory_sources', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'groups-total', nlabel => 'inventory.groups.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total_groups' }, { name => 'display' } ],
                output_template => 'groups total: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'groups-failed', nlabel => 'inventory.groups.failed.count', set => {
                key_values => [
                    { name => 'groups_with_active_failures' }, { name => 'total_groups' }, 
                    { name => 'display' }
                ],
                output_template => 'Groups failed: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_groups', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-inventory:s' => { name => 'filter_inventory' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $inventories = $options{custom}->tower_list_inventories();

    $self->{global} = { total => 0, failed => 0 };
    $self->{inventories} = {};
    foreach my $inventory (@$inventories) {
        next if (defined($self->{option_results}->{filter_inventory}) && $self->{option_results}->{filter_inventory} ne '' 
            && $inventory->{name} !~ /$self->{option_results}->{filter_inventory}/);

        $self->{inventories}->{ $inventory->{id} } = {
            display => $inventory->{name},
            total_hosts => $inventory->{total_hosts},
            hosts_with_active_failures => $inventory->{hosts_with_active_failures},
            total_inventory_sources => $inventory->{total_inventory_sources},
            inventory_sources_with_failures => $inventory->{inventory_sources_with_failures},
            total_groups => $inventory->{total_groups},
            groups_with_active_failures => $inventory->{groups_with_active_failures}
        };
        $self->{global}->{total}++;

        $self->{global}->{failed}++ if ($inventory->{has_active_failures});
    }
}

1;

__END__

=head1 MODE

Check inventories.

=over 8

=item B<--filter-inventory>

Filter inventory name (Can use regexp).

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'total', 'failed', 'hosts-total', 'hosts-failed', 
'sources-total', 'sources-failed', 'groups-total', 'groups-failed'.

=back

=cut
