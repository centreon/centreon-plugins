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

package cloud::azure::management::costs::mode::hybridbenefits;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_orphaned_output {
    my ($self, %options) = @_;

    my $msg = sprintf(" resources without hybrid benefits %s (out of: %s)", $self->{result_values}->{count}, $self->{result_values}->{total});
    
    return $msg;
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return 'Virtual machines';
}

sub prefix_sql_vm_output {
    my ($self, %options) = @_;

    return 'SQL Virtual machines';
}

sub prefix_sql_db_output {
    my ($self, %options) = @_;

    return 'SQL Databases';
}

sub prefix_elasticpool_output {
    my ($self, %options) = @_;

    return 'SQL Elastic Pools';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'skip-vm'               => { name => 'skip_vm' },
        'skip-sql-vm'           => { name => 'skip_sql_vm' },
        'skip-sql-database'     => { name => 'skip_sql_database' },
        'skip-elastic-pool'     => { name => 'skip_elastic_pool' },
        'exclude-name:s'        => { name => 'exclude_name' }
    });

    return $self;
}

sub set_counters { 
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nohybridbenefits_resources', type => 0 },
        { name => 'nohybridbenefits_vm', type => 0, cb_prefix_output => 'prefix_vm_output' },
        { name => 'nohybridbenefits_sql_vm', type => 0, cb_prefix_output => 'prefix_sql_vm_output' },
        { name => 'nohybridbenefits_sql_db', type => 0, cb_prefix_output => 'prefix_sql_db_output' },
        { name => 'nohybridbenefits_elasticpool', type => 0, cb_prefix_output => 'prefix_elasticpool_output' }
    ];

# vm, sql-vm, sql-database, elastic-pool
    $self->{maps_counters}->{nohybridbenefits_resources} = [
        { label => 'resources', nlabel => 'azure.resources.nohybridbenefits.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                output_template => 'Resources without hybrid benefits: %s',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{nohybridbenefits_vm} = [
        { label => 'vm', display_ok => 0, nlabel => 'azure.vm.nohybridbenefits.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_hybridbenefits_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{nohybridbenefits_sql_vm} = [
        { label => 'sql-vm', display_ok => 0, nlabel => 'azure.sqlvm.nohybridbenefits.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_hybridbenefits_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{nohybridbenefits_sql_db} = [
        { label => 'sql-database', display_ok => 0, nlabel => 'azure.sqldatabase.nohybridbenefits.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_hybridbenefits_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{nohybridbenefits_elasticpool} = [
        { label => 'elastic-pool', display_ok => 0, nlabel => 'azure.elasticpool.nohybridbenefits.count', set => {
                key_values => [ { name => 'count' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_hybridbenefits_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $resultset;
    my @item_list;
    $self->{nohybridbenefits_resources}->{count} = 0;
    $self->{nohybridbenefits_resources}->{total} = 0;

    # VMs
    if (!defined($self->{option_results}->{skip_vm})) {
        $self->{nohybridbenefits_vm}->{count} = 0;
        $self->{nohybridbenefits_vm}->{total} = 0;
        $resultset = $options{custom}->azure_list_vms(
            resource_group => $self->{option_results}->{resource_group},
            force_api_version => "2022-03-01"
        );
        
        foreach my $item (@{ $resultset}) {
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{vm_hybrid_benefits}->{total}++;
            $self->{nohybridbenefits_resources}->{total}++;
            next if (!defined($item->{properties}->{licenseType}) || (defined($item->{properties}->{licenseType}) && $item->{properties}->{licenseType} !~ /None/));
            $self->{nohybridbenefits_vm}->{count}++;
            $self->{nohybridbenefits_resources}->{count}++;
            push @item_list, $item->{name};
        }
        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "Virtual Machines withtout hybrid benefits:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = ();
    }

    # SQL VMs
    if (!defined($self->{option_results}->{skip_sql_vm})) {
        $self->{nohybridbenefits_sql_vm}->{count} = 0;
        $self->{nohybridbenefits_sql_vm}->{total} = 0;
        $resultset = $options{custom}->azure_list_sqlvms(
            resource_group => $self->{option_results}->{resource_group},
            force_api_version => "2022-02-01"
        );
        foreach my $item (@{ $resultset}) {
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
			$self->{nohybridbenefits_sql_vm}->{total}++;
            $self->{nohybridbenefits_resources}->{total}++;
            next if ($item->{properties}->{sqlServerLicenseType } =~ /AHUB/ || $item->{properties}->{sqlImageSku} =~ /Express/);
            $self->{nohybridbenefits_sql_vm}->{count}++;
            $self->{nohybridbenefits_resources}->{count}++;
			push @item_list, $item->{name};
        }
        if (scalar @item_list != 0) {
            $self->{output}->output_add(long_msg => "SQL Virtual Machines withtout hybrid benefits:" . "[" . join(", ", @item_list) . "]");
        }
        @item_list = ();
        
    }

    if (!defined($self->{option_results}->{skip_sql_vm}) || !defined($self->{option_results}->{skip_elastic_pool})) {
		my @item_list_sql;
		my @item_list_elastic;
        $resultset = $options{custom}->azure_list_sqlservers(
            resource_group => $self->{option_results}->{resource_group},
            force_api_version => "2021-11-01"
        );

        $self->{nohybridbenefits_elasticpool}->{count} = 0;
        $self->{nohybridbenefits_elasticpool}->{total} = 0;	 
        $self->{nohybridbenefits_sql_db}->{count} = 0;
        $self->{nohybridbenefits_sql_db}->{total} = 0;

        foreach my $item (@{$resultset}) {
            my @sqlserver_id = split /\//, $item->{id};
    
            # SQL databases
            if (!defined($self->{option_results}->{skip_sql_database})) {			
                my $resultset_sql = $options{custom}->azure_list_sqldatabases(
                    resource_group => $sqlserver_id[4],
                    server => $item->{name},
                    force_api_version => "2021-11-01"
                );

                foreach my $item_sql (@{ $resultset_sql}) {
                    next if ($item_sql->{properties}->{currentSku}->{name} =~ /ElasticPool/);
                    next if (defined($item_sql->{properties}->{currentSku}->{tier}) && $item_sql->{properties}->{currentSku}->{tier} !~ /GeneralPurpose/);
                    next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                         && $item_sql->{name} =~ /$self->{option_results}->{exclude_name}/);
                    next if (defined($item_sql->{properties}->{licenseType}) && $item_sql->{properties}->{licenseType} eq "BasePrice");
                    $self->{nohybridbenefits_sql_db}->{total}++;
                    $self->{nohybridbenefits_resources}->{total}++;

                    if (defined($item_sql->{properties}->{licenseType})) {
                        $self->{nohybridbenefits_sql_db}->{count}++;
                        $self->{nohybridbenefits_resources}->{count}++;
						push @item_list_sql, $item_sql->{name};
                    }
                }
			}

            # SQL Elastic pools
            if (!defined($self->{option_results}->{skip_elastic_pool})) {
                my $resultset_elastic = $options{custom}->azure_list_sqlelasticpools(
                    resource_group => $sqlserver_id[4],
                    server => $item->{name},
                    force_api_version => "2021-11-01"
                );
           
                foreach my $item_ep (@{$resultset_elastic}) {		
                    next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                         && $item_ep->{name} =~ /$self->{option_results}->{exclude_name}/);
			    	$self->{nohybridbenefits_elasticpool}->{total}++;
                    $self->{nohybridbenefits_resources}->{total}++;
                    next if (defined($item_ep->{properties}->{licenseType}) && $item_ep->{properties}->{licenseType} =~ /BasePrice/);
			    	$self->{nohybridbenefits_elasticpool}->{count}++;
                    $self->{nohybridbenefits_resources}->{count}++;
					push @item_list_elastic, $item_ep->{name};
                }
            }
		}
        if (scalar @item_list_sql != 0) {
            $self->{output}->output_add(long_msg => "SQL Databases withtout hybrid benefits:" . "[" . join(", ", @item_list_sql) . "]");
        }
        if (scalar @item_list_elastic != 0) {
            $self->{output}->output_add(long_msg => "SQL Elastic pools withtout hybrid benefits:" . "[" . join(", ", @item_list_elastic) . "]");
        }
	}
}

1;

__END__

=head1 MODE

Check if hybrid benefits is enabled on eligible resources.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --custommode=api --mode=hybrid-benefits
{--resource-group='MYRESOURCEGROUP'] --exclude-name='MyDb|MyEpool.*' [--skip-vm] [--skip-sql-vm] [--skip-sql-database] [--skip-sql-elastic-pool] [--show-details --verbose]

Adding --verbose will display the item names.

=over 8

=item B<--resource-group>

Set resource group.

=item B<--exclude-name>

Exclude resource from check (can be a regexp).

=item B<--warning-*>

Warning threshold on the number of orphaned resources. 
Substitue '*' by the resource type amongst this list: 
    ( elastic-pool sql-database vm sql-vm resources)

=îtem B<--critical-*>

Critical threshold on the number of orphaned resources. 
Substitue '*' by the resource type amongst this list: 
    (elastic-pool sql-database vm sql-vm resources)

=item B<--skip-*>

Skip a specific kind of resource. Can be multiple.

Accepted values: vm, sql-vm, sql-database, elastic-pool

=back

=back

=cut
