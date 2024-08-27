#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package cloud::azure::management::costs::mode::orphanresources;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_orphaned_output {
    my ($self, %options) = @_;

    my $msg = sprintf(" orphaned resources %s (total: %s)", $self->{result_values}->{count}, $self->{result_values}->{total});
    
    return $msg;
}

sub prefix_disks_output {
    my ($self, %options) = @_;

    return 'Managed disks';
}

sub prefix_nsgs_output {
    my ($self, %options) = @_;

    return 'NSGs';
}

sub prefix_nics_output {
    my ($self, %options) = @_;

    return 'NICs';
}

sub prefix_publicips_output {
    my ($self, %options) = @_;

    return 'Public IPs';
}

sub prefix_routetables_output {
    my ($self, %options) = @_;

    return 'Route tables';
}

sub prefix_snapshots_output {
    my ($self, %options) = @_;

    return 'Snapshots';    
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'exclude-name:s'       => { name => 'exclude_name' },
        'skip-managed-disks'   => { name => 'skip_managed_disks' },
        'skip-nics'            => { name => 'skip_nics' },
        'skip-nsgs'            => { name => 'skip_nsgs' },
        'skip-public-ips'      => { name => 'skip_public_ips' },
        'skip-route-tables'    => { name => 'skip_route_tables' },
        'skip-snapshots'       => { name => 'skip_snapshots' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub set_counters { 
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'orphaned_resources', type => 0 },
        { name => 'orphaned_disks', type => 0, cb_prefix_output => 'prefix_disks_output' },
        { name => 'orphaned_nics', type => 0, cb_prefix_output => 'prefix_nics_output' },
        { name => 'orphaned_nsgs', type => 0, cb_prefix_output => 'prefix_nsgs_output' },
        { name => 'orphaned_publicips', type => 0, cb_prefix_output => 'prefix_publicips_output' },
        { name => 'orphaned_routetables', type => 0, cb_prefix_output => 'prefix_routetables_output' },
        { name => 'orphaned_snapshots', type => 0, cb_prefix_output => 'prefix_snapshots_output' }
    ];

# nics, nsgs, public-ips, route-tables, snapshots
    $self->{maps_counters}->{orphaned_resources} = [
        { label => 'orphaned-resources', nlabel => 'azure.resources.orphaned.count', set => {
                key_values => [ { name => 'count' }, { name => 'total'} ],
                output_template => 'Orphaned resources: %s',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{orphaned_disks} = [
        { label => 'orphaned-managed-disks', display_ok => 0, nlabel => 'azure.manageddisks.orphaned.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_orphaned_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{orphaned_nics} = [
        { label => 'orphaned-nics', display_ok => 0, nlabel => 'azure.nics.orphaned.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_orphaned_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{orphaned_nsgs} = [
        { label => 'orphaned-nsgs', display_ok => 0, nlabel => 'azure.nsgs.orphaned.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_orphaned_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{orphaned_publicips} = [
        { label => 'orphaned-publicips', display_ok => 0, nlabel => 'azure.publicips.orphaned.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_orphaned_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{orphaned_routetables} = [
        { label => 'orphaned-routetables', display_ok => 0, nlabel => 'azure.routetables.orphaned.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_orphaned_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{orphaned_snapshots} = [
        { label => 'orphaned-snapshots', display_ok => 0, nlabel => 'azure.snapshots.orphaned.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_orphaned_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total'}
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $resultset;
    my @item_list;
    $self->{orphaned_resources}->{count} = 0;
    $self->{orphaned_resources}->{total} = 0;

    # orphan managed disks
    if (!defined($self->{option_results}->{skip_managed_disks})) {
        $self->{orphaned_disks}->{count} = 0;
        $self->{orphaned_disks}->{total} = 0;
	    $resultset = $options{custom}->azure_list_compute_disks(
	        resource_group => $self->{option_results}->{resource_group},
	        force_api_version => "2022-07-02"
	    );
	    foreach my $item (@{$resultset}) {
	        next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
	    	     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{orphaned_disks}->{total}++;
            $self->{orphaned_resources}->{total}++;
	        next if ($item->{properties}->{diskState} !~ /Unattached/);
            $self->{orphaned_disks}->{count}++;
            $self->{orphaned_resources}->{count}++;
            push @item_list, $item->{name};
	    }
        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "Managed Disks orphaned list:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = ();
    }

     # orphan NICs
    if (!defined($self->{option_results}->{skip_nics})) {
        $self->{orphaned_nics}->{count} = 0;
        $self->{orphaned_nics}->{total} = 0;
        $resultset = $options{custom}->azure_list_nics(
            resource_group => $self->{option_results}->{resource_group},
	        force_api_version => "2022-05-01"
        );
	    foreach my $item (@{$resultset}) {
	        next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
	    	     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{orphaned_nics}->{total}++;
            $self->{orphaned_resources}->{total}++;
            next if (scalar(keys %{$item->{properties}->{virtualMachine}}) != 0 || defined($item->{properties}->{privateEndpoint}));
            $self->{orphaned_nics}->{count}++;
            $self->{orphaned_resources}->{count}++;
            push @item_list, $item->{name};
	    }
        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "NICs orphaned list:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = (); 
    }

    # orphan NSGs
    if (!defined($self->{option_results}->{skip_nsgs})) {
        $self->{orphaned_nsgs}->{count} = 0;
        $self->{orphaned_nsgs}->{total} = 0;

        $resultset = $options{custom}->azure_list_nsgs(
            resource_group => $self->{option_results}->{resource_group},
            force_api_version => "2022-05-01"
        );
	    foreach my $item (@{$resultset}) {          
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{orphaned_nsgs}->{total}++;
            $self->{orphaned_resources}->{total}++;
            next if (defined($item->{properties}->{subnets}) && scalar($item->{properties}->{subnets}) != 0);
            next if (defined($item->{properties}->{networkInterface}) && scalar($item->{properties}->{networkInterface}) != 0);
            next if (defined($item->{properties}->{networkInterfaces}) && scalar($item->{properties}->{networkInterfaces}) != 0);
            $self->{orphaned_nsgs}->{count}++;
            $self->{orphaned_resources}->{count}++;
            push @item_list, $item->{name};
	    }
        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "NSGs orphaned list:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = (); 
    }

    # orphan public IPs
    if (!defined($self->{option_results}->{skip_public_ips})) {
        $self->{orphaned_publicips}->{count} = 0;
        $self->{orphaned_publicips}->{total} = 0;
        $resultset = $options{custom}->azure_list_publicips(
            resource_group => $self->{option_results}->{resource_group},
            force_api_version => "2022-01-01"
        );
        foreach my $item (@{$resultset}) {
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{orphaned_publicips}->{total}++;
            $self->{orphaned_resources}->{total}++;
            next if (defined($item->{properties}->{ipConfiguration}) && scalar($item->{properties}->{ipConfiguration}) != 0);
            $self->{orphaned_publicips}->{count}++;
            $self->{orphaned_resources}->{count}++;
            push @item_list, $item->{name};
	    }
        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "Public IPs orphaned list:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = ();
    }



    # orphan route tables
    if (!defined($self->{option_results}->{skip_route_tables})) {
        $self->{orphaned_routetables}->{count} = 0;
        $self->{orphaned_routetables}->{total} = 0;
        $resultset = $options{custom}->azure_list_route_tables(
            resource_group => $self->{option_results}->{resource_group},
            force_api_version => "2022-01-01"
        );
        foreach my $item (@{$resultset}) {
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{orphaned_routetables}->{total}++;
            $self->{orphaned_resources}->{total}++;
            next if (defined($item->{properties}->{subnets}) && scalar($item->{properties}->{subnets}) != 0);
            $self->{orphaned_routetables}->{count}++;
            $self->{orphaned_resources}->{count}++;
            push @item_list, $item->{name};
	    }
        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "Route tables orphaned list:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = ();
    }


    # orphan snapshots
    if (!defined($self->{option_results}->{skip_snapshots})) {
        $self->{orphaned_snapshots}->{count} = 0;
        $self->{orphaned_snapshots}->{total} = 0;
        $resultset = $options{custom}->azure_list_snapshots(
            resource_group => $self->{option_results}->{resource_group},
            force_api_version => "2021-12-01"
        );
        foreach my $item (@{$resultset}) {
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{orphaned_snapshots}->{total}++;
            $self->{orphaned_resources}->{total}++;
            next if (defined($item->{properties}->{subnets}) && scalar($item->{properties}->{subnets}) != 0);
            $self->{orphaned_snapshots}->{count}++;
            $self->{orphaned_resources}->{count}++;
            push @item_list, $item->{name};
	    }
        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "Snapshots orphaned list:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = ();
    }

}

1;

__END__

=head1 MODE

Check orphaned resource within an Azure subscription.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --custommode=api --mode=orphan-resource
{--resource-group='MYRESOURCEGROUP'] --exclude-name='MyDisk|DataDisk.*' [--skip-managed-disks] [--skip-nics] [--skip-nsgs] [--skip-public-ips] [--skip-route-tables] [--skip-snapshots]

Adding --verbose will display the item names.

=over 8

=item B<--resource-group>

Set resource group.

=item B<--exclude-name>

Exclude resource from check (can be a regexp).

=item B<--warning-*>

Warning threshold on the number of orphaned resources. 
Substitue '*' by the resource type amongst this list: 
    (orphaned-snapshots orphaned-routetables orphaned-managed-disks orphaned-nsgs orphaned-nics orphaned-resources orphaned-publicips)

=îtem B<--critical-*>

Critical threshold on the number of orphaned resources. 
Substitue '*' by the resource type amongst this list: 
    (orphaned-snapshots orphaned-routetables orphaned-managed-disks orphaned-nsgs orphaned-nics orphaned-resources orphaned-publicips)

=item B<--skip-*>

Skip a specific kind of resource. Can be multiple.

Accepted values: disks, nics, nsgs, public-ips, route-tables, snapshots

=back

=cut