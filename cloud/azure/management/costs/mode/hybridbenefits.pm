#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'no-vm-hybrid-benefits'               => { name => 'no_vm_hybrid_benefits' },
        'no-sql-vm-hybrid-benefits'           => { name => 'no_sql_vm_hybrid_benefits' },
        'no-sql-database-hybrid-benefits'     => { name => 'no_sql_database_hybrid_benefits' },
        'no-sql-elastic-pool-hybrid-benefits' => { name => 'no_sql_elastic_pool_hybrid_benefits' },
	'exclude-name:s'                      => { name => 'exclude_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $output_error = "";
    my $output = "";
    my $items;

    # non HUB VMs
    if (!defined($self->{option_results}->{no_vm_hybrid_benefits})) {
	$items = $options{custom}->azure_list_vms(
	    resource_group => $self->{option_results}->{resource_group},
	    api_version_override => "2022-03-01"
	    );
	$self->{vm_hybrid_benefits} = {not_enabled => 0, total => 0, name => ""};
	foreach my $item (@{$items}) {
	    $self->{vm_hybrid_benefits}->{total}++;;
	    next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
		     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
	    next if (!defined($item->{properties}->{licenseType}) || (defined($item->{properties}->{licenseType}) && $item->{properties}->{licenseType} !~ /None/));
	    $self->{vm_hybrid_benefits}->{not_enabled}++;
	    $self->{vm_hybrid_benefits}->{name} .= $item->{name} . " ";
	}
	if ($self->{vm_hybrid_benefits}->{not_enabled}) {
	    $output_error .= "Found " . $self->{vm_hybrid_benefits}->{not_enabled} . " VM(s) with VmHybridBenefits not enabled ( " . $self->{vm_hybrid_benefits}->{name} . ")\n";
	}
	else {
	    $output .= "VmHybridBenefits is enabled on all " . $self->{vm_hybrid_benefits}->{total} . " VM(s)\n";
	}
    }

    # non HUB SQL VMs
    if (!defined($self->{option_results}->{no_sql_vm_hybrid_benefits})) {
        $items = $options{custom}->azure_list_sqlvms(
            resource_group => $self->{option_results}->{resource_group},
	    api_version_override => "2022-02-01"
            );
        $self->{sql_vm_hybrid_benefits} = {not_enabled => 0, total => 0, name => ""};
        foreach my $item (@{$items}) {
            $self->{sql_vm_hybrid_benefits}->{total}++;;
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
	    next if ($item->{properties}->{sqlServerLicenseType } =~ /AHUB/ || $item->{properties}->{sqlImageSku} =~ /Express/);
            $self->{sql_vm_hybrid_benefits}->{not_enabled}++;
            $self->{sql_vm_hybrid_benefits}->{name} .= $item->{name} . " ";
        }
        if ($self->{sql_vm_hybrid_benefits}->{not_enabled}) {
            $output_error .= "Found " . $self->{sql_vm_hybrid_benefits}->{not_enabled} . " SQL VM(s) with VmHybridBenefits not enabled ( " . $self->{sql_vm_hybrid_benefits}->{name} . ")\n";
        }
        else {
            $output .= "SqlVmHybridBenefits is enabled on all " . $self->{sql_vm_hybrid_benefits}->{total} . " SQL VM(s)\n";
        }
    }

    if (!defined($self->{option_results}->{no_sql_database_hybrid_benefits}) || !defined($self->{option_results}->{no_sql_elastic_pool_hybrid_benefits})) {
        $items = $options{custom}->azure_list_sqlservers(
            resource_group => $self->{option_results}->{resource_group},
            api_version_override => "2021-11-01"
            );
	$self->{sql_database_hybrid_benefits} = {not_enabled => 0, total => 0, name => ""};
	$self->{sql_elastic_pool_hybrid_benefits} = {not_enabled => 0, total => 0, name => ""};
        foreach my $item (@{$items}) {
	    my @sqlserver_id = split /\//, $item->{id};
	
	    # non HUB SQL databases
	    if (!defined($self->{option_results}->{no_sql_database_hybrid_benefits})) {
		my $items_sub = $options{custom}->azure_list_sqldatabases(
		    resource_group => $sqlserver_id[4],
		    server => $item->{name},
		    api_version_override => "2021-11-01"
		    );
		
		foreach my $item_sub (@{$items_sub}) {
		    next if ($item_sub->{properties}->{currentSku}->{name} =~ /ElasticPool/);
		    next if (defined($item_sub->{properties}->{currentSku}->{tier}) && $item_sub->{properties}->{currentSku}->{tier} !~ /GeneralPurpose/);
		    $self->{sql_database_hybrid_benefits}->{total}++;;
		    next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
			     && $item_sub->{name} =~ /$self->{option_results}->{exclude_name}/);
		    next if (defined($item_sub->{properties}->{licenseType}) && $item_sub->{properties}->{licenseType} =~ /BasePrice/);
		    if (defined($item_sub->{properties}->{licenseType})) {
			$self->{sql_database_hybrid_benefits}->{not_enabled}++;
			$self->{sql_database_hybrid_benefits}->{name} .= $item_sub->{name} . " ";
		    }
		}
	    }

	    # non HUB Elastic pool
	    if (!defined($self->{option_results}->{no_sql_elastic_pool_hybrid_benefits})) {
		my $items_sub = $options{custom}->azure_list_sqlelasticpools(
		    resource_group => $sqlserver_id[4],
		    server => $item->{name},
		    api_version_override => "2021-11-01"
		    );
		
		foreach my $item_sub (@{$items_sub}) {
		    $self->{sql_elastic_pool_hybrid_benefits}->{total}++;;
		    next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
			     && $item_sub->{name} =~ /$self->{option_results}->{exclude_name}/);
		    next if (defined($item_sub->{properties}->{licenseType}) && $item_sub->{properties}->{licenseType} =~ /BasePrice/);
		    $self->{sql_elastic_pool_hybrid_benefits}->{not_enabled}++;
		    $self->{sql_elastic_pool_hybrid_benefits}->{name} .= $item_sub->{name} . " ";
		}
	    }
	}
	if (!defined($self->{option_results}->{no_sql_database_hybrid_benefits})) {
	    if ($self->{sql_database_hybrid_benefits}->{not_enabled}) {
		$output_error .= "Found " . $self->{sql_database_hybrid_benefits}->{not_enabled} . " SQL database(s) with SqlDatabaseHybridBenefits not enabled ( " . $self->{sql_database_hybrid_benefits}->{name} . ")\n";
	    }
	    else {
		$output .= "SqlDatabaseHybridBenefits is enabled on all " . $self->{sql_database_hybrid_benefits}->{total} . " eligible SQL database(s)\n";
	    }
	}

	if (!defined($self->{option_results}->{no_sql_elastic_pool_hybrid_benefits})) {
	    if ($self->{sql_elastic_pool_hybrid_benefits}->{not_enabled}) {
		$output_error .= "Found " . $self->{sql_elastic_pool_hybrid_benefits}->{not_enabled} . " SQL elastic pool(s) with SqlElasticPoolHybridBenefits not enabled ( " . $self->{sql_elastic_pool_hybrid_benefits}->{name} . ")\n";
	    }
	    else {
	    $output .= "SqlElasticPoolHybridBenefits is enabled on all " . $self->{sql_elastic_pool_hybrid_benefits}->{total} . " eligible SQL elastic pool(s)\n";
	    }	
	}
    }
    if ($output_error) {
	$self->{output}->output_add(severity => "CRITICAL", short_msg => $output_error . $output);
    }
    else {
	$self->{output}->output_add(severity => "OK", short_msg => "Everything is OK\n" . $output);
    }
}

1;

__END__

=head1 MODE

Check if hybrid benefits is enabled on eligible resources.

Since there are multiple calls to multiple Rest APIs versions, api-version parameter is hardcoded in the mode code.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --custommode=api --mode=hybrid-benefits
{--resource-group='MYRESOURCEGROUP'] --exclude-name='MyDb|MyEpool.*' [--no-vm-hybrid-benefits] [--no-sql-vm-hybrid-benefits] [--no-sql-database-hybrid-benefits] [--no-sql-elastic-pool-hybrid-benefits]


=over 8

=item B<--resource-group>

Set resource group (Required).

=item B<--exclude-name>

Exclude resource from check (Can be a regexp).

=item B<--no-vm-hybrid-benefits --no-sql-vm-hybrid-benefits --no-sql-database-hybrid-benefits --no-sql-elastic-pool-hybrid-benefits>

Exclude resource type from check

=back

=cut
