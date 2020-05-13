#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::automation::ansible::tower::mode::inventorystatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output', cb_init => 'skip_global' },
        { name => 'inventories', type => 1, cb_prefix_output => 'prefix_output_inventories',
          message_multiple => 'All inventories statistics are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'inventories.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total: %d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'failed', nlabel => 'inventories.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'total' } ],
                output_template => 'Failed: %d',
                perfdatas => [
                    { value => 'failed', template => '%d', min => 0,
                      max => 'total' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{inventories} = [
        { label => 'hosts-total', nlabel => 'inventory.hosts.total.count', set => {
                key_values => [ { name => 'total_hosts' }, { name => 'display' } ],
                output_template => 'Hosts total: %d',
                perfdatas => [
                    { value => 'total_hosts', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'hosts-failed', nlabel => 'inventory.hosts.failed.count', set => {
                key_values => [ { name => 'hosts_with_active_failures' }, { name => 'total_hosts' }, 
                                { name => 'display' } ],
                output_template => 'Hosts failed: %d',
                perfdatas => [
                    { value => 'hosts_with_active_failures', template => '%d',
                      min => 0, max => 'total_hosts', label_extra_instance => 1,
                      instance_use => 'display' },
                ],
            }
        },
        { label => 'sources-total', nlabel => 'inventory.sources.total.count', set => {
                key_values => [ { name => 'total_inventory_sources' }, { name => 'display' } ],
                output_template => 'Sources total: %d',
                perfdatas => [
                    { value => 'total_inventory_sources', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'sources-failed', nlabel => 'inventory.sources.failed.count', set => {
                key_values => [ { name => 'inventory_sources_with_failures' }, { name => 'total_inventory_sources' }, 
                                { name => 'display' } ],
                output_template => 'Sources failed: %d',
                perfdatas => [
                    { value => 'inventory_sources_with_failures', template => '%d',
                      min => 0, max => 'total_inventory_sources', label_extra_instance => 1,
                      instance_use => 'display' },
                ],
            }
        },
        { label => 'groups-total', nlabel => 'inventory.groups.total.count', set => {
                key_values => [ { name => 'total_groups' }, { name => 'display' } ],
                output_template => 'Groups total: %d',
                perfdatas => [
                    { value => 'total_groups', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'groups-failed', nlabel => 'inventory.groups.failed.count', set => {
                key_values => [ { name => 'groups_with_active_failures' }, { name => 'total_groups' }, 
                                { name => 'display' } ],
                output_template => 'Groups failed: %d',
                perfdatas => [
                    { value => 'groups_with_active_failures', template => '%d',
                      min => 0, max => 'total_groups', label_extra_instance => 1,
                      instance_use => 'display' },
                ],
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;
    
    scalar(keys %{$self->{inventories}}) > 1 ? return(0) : return(1);
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Inventories ";
}

sub prefix_output_inventories {
    my ($self, %options) = @_;

    return "Inventory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-inventory:s' => { name => 'filter_inventory' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{global} = { total => 0, failed => 0 };

    my $inventories = $options{custom}->tower_list_inventories();

    $self->{global}->{total} = $inventories->{count};

    foreach my $inventory (@{$inventories->{results}}) {
        next if (defined($self->{option_results}->{filter_inventory}) && $self->{option_results}->{filter_inventory} ne '' 
            && $inventory->{name} !~ /$self->{option_results}->{filter_inventory}/);
        
        $self->{inventories}->{$inventory->{id}} = {
            display => $inventory->{name},
            total_hosts => $inventory->{total_hosts},
            hosts_with_active_failures => $inventory->{hosts_with_active_failures},
            total_inventory_sources => $inventory->{total_inventory_sources},
            inventory_sources_with_failures => $inventory->{inventory_sources_with_failures},
            total_groups => $inventory->{total_groups},
            groups_with_active_failures => $inventory->{groups_with_active_failures},
        };

        $self->{global}->{failed}++ if ($inventory->{has_active_failures});
    }
}

1;

__END__

=head1 MODE

Check inventories statistics.

=over 8

=item B<--filter-inventory>

Filter inventory name (Can use regexp).

=item B<--warning-inventories-*-count>

Threshold warning.
Can be: 'total', 'failed'.

=item B<--critical-inventories-*-count>

Threshold critical.
Can be: 'total', 'failed'.

=item B<--warning-instance-inventory.*.*.count>

Threshold warning.
Can be 'hosts', 'sources', 'groups' and 'total', 'failed'.

=item B<--critical-instance-inventory.*.*.count>

Threshold critical.
Can be 'hosts', 'sources', 'groups' and 'total', 'failed'
'indexes'.

=back

=cut
