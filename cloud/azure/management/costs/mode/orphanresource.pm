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

package cloud::azure::management::costs::mode::orphanresource;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'no-managed-disks'   => { name => 'no_managed_disks' },
        'no-nics'            => { name => 'no_nics' },
        'no-nsgs'            => { name => 'no_nsgs' },
        'no-public-ips'      => { name => 'no_public_ips' },
        'no-route-tables'    => { name => 'no_route_tables' },
        'no-snapshots'       => { name => 'no_snapshots' },
	'exclude-name:s'     => { name => 'exclude_name' }
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

    # orphan managed disks
    if (!defined($self->{option_results}->{no_managed_disks})) {
	$items = $options{custom}->azure_list_compute_disks(
	    resource_group => $self->{option_results}->{resource_group},
	    api_version_override => "2022-07-02"
	    );
	$self->{disks} = {orphan => 0, total => 0, name => ""};
	foreach my $item (@{$items}) {
	    $self->{disks}->{total}++;;
	    next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
		     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
	    next if ($item->{properties}->{diskState} !~ /Unattached/);
	    $self->{disks}->{orphan}++;
	    $self->{disks}->{name} .= $item->{name} . " ";
	}
	if ($self->{disks}->{orphan}) {
	    $output_error .= "Found " . $self->{disks}->{orphan} . " orphan managed disk(s) ( " . $self->{disks}->{name} . ")\n";
	}
	else {
	    $output .= "No orphan managed disk found on " . $self->{disks}->{total} . " total disk(s)\n";
	}
    }

    # orphan NICs
    if (!defined($self->{option_results}->{no_nics})) {
        $items = $options{custom}->azure_list_nics(
            resource_group => $self->{option_results}->{resource_group},
	    api_version_override => "2022-05-01"
            );
        $self->{nics} = {orphan => 0, total => 0, name => ""};
        foreach my $item (@{$items}) {
            $self->{nics}->{total}++;;
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            next if (scalar(keys %{$item->{properties}->{virtualMachine}}) != 0 || defined($item->{properties}->{privateEndpoint}));
            $self->{nics}->{orphan}++;
	    $self->{nics}->{name} .= $item->{name} . " ";
        }
        if ($self->{nics}->{orphan}) {
            $output_error .= "Found " . $self->{nics}->{orphan} . " orphan NIC(s) ( " . $self->{nics}->{name} . ")\n";
        }
	else {
	    $output .= "No orphan NIC found on " . $self->{nics}->{total} . " total NIC(s)\n";
	}
    }

    # orphan NSGs
    if (!defined($self->{option_results}->{no_nsgs})) {
        $items = $options{custom}->azure_list_nsgs(
            resource_group => $self->{option_results}->{resource_group},
            api_version_override => "2022-05-01"
            );
        $self->{nsgs} = {orphan => 0, total => 0, name => ""};
        foreach my $item (@{$items}) {
            $self->{nsgs}->{total}++;;
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            next if (defined($item->{properties}->{subnets}) && scalar($item->{properties}->{subnets}) != 0);
            next if (defined($item->{properties}->{networkInterface}) && scalar($item->{properties}->{networkInterface}) != 0);
            next if (defined($item->{properties}->{networkInterfaces}) && scalar($item->{properties}->{networkInterfaces}) != 0);
            $self->{nsgs}->{orphan}++;
            $self->{nsgs}->{name} .= $item->{name} . " ";
        }
        if ($self->{nsgs}->{orphan}) {
            $output_error .= "Found " . $self->{nsgs}->{orphan} . " orphan NSG(s) ( " . $self->{nsgs}->{name} . ")\n";
        }
        else {
            $output .= "No orphan NSG found on " . $self->{nsgs}->{total} . " total NSG(s)\n";
        }
    }

    # orphan public IPs
    if (!defined($self->{option_results}->{no_public_ips})) {
        $items = $options{custom}->azure_list_publicips(
            resource_group => $self->{option_results}->{resource_group},
            api_version_override => "2022-01-01"
            );
        $self->{public_ips} = {orphan => 0, total => 0, name => ""};
        foreach my $item (@{$items}) {
            $self->{public_ips}->{total}++;;
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            next if (defined($item->{properties}->{ipConfiguration}) && scalar($item->{properties}->{ipConfiguration}) != 0);
            $self->{public_ips}->{orphan}++;
            $self->{public_ips}->{name} .= $item->{name} . " ";
        }
        if ($self->{public_ips}->{orphan}) {
            $output_error .= "Found " . $self->{public_ips}->{orphan} . " orphan public IP(s) ( " . $self->{public_ips}->{name} . ")\n";
        }
        else {
            $output .= "No orphan public IP found on " . $self->{public_ips}->{total} . " total public IP(s)\n";
        }
    }

    # orphan route tables
    if (!defined($self->{option_results}->{no_route_tables})) {
        $items = $options{custom}->azure_list_route_tables(
            resource_group => $self->{option_results}->{resource_group},
            api_version_override => "2022-01-01"
            );
        $self->{route_tables} = {orphan => 0, total => 0, name => ""};
        foreach my $item (@{$items}) {
            $self->{route_tables}->{total}++;;
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            next if (defined($item->{properties}->{subnets}) && scalar($item->{properties}->{subnets}) != 0);
            $self->{route_tables}->{orphan}++;
            $self->{route_tables}->{name} .= $item->{name} . " ";
        }
        if ($self->{route_tables}->{orphan}) {
            $output_error .= "Found " . $self->{route_tables}->{orphan} . " orphan route table(s) ( " . $self->{route_tables}->{name} . ")\n";
        }
        else {
            $output .= "No orphan route table found on " . $self->{route_tables}->{total} . " total route table(s)\n";
        }
    }

    # orphan snapshots
    if (!defined($self->{option_results}->{no_snapshots})) {
        $items = $options{custom}->azure_list_snapshots(
            resource_group => $self->{option_results}->{resource_group},
            api_version_override => "2021-12-01"
            );
        $self->{snapshots} = {orphan => 0, total => 0, name => ""};
        foreach my $item (@{$items}) {
            $self->{snapshots}->{total}++;;
            next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne ''
                     && $item->{name} =~ /$self->{option_results}->{exclude_name}/);
            $self->{snapshots}->{orphan}++;
            $self->{snapshots}->{name} .= $item->{name} . " ";
        }
        if ($self->{snapshots}->{orphan}) {
            $output_error .= "Found " . $self->{snapshots}->{orphan} . " orphan snapshot(s) ( " . $self->{snapshots}->{name} . ")\n";
        }
        else {
            $output .= "No orphan snapshot found on " . $self->{snapshots}->{total} . " total snapshot(s)\n";
        }
    }

    if ($output_error) {
	$self->{output}->output_add(severity => "CRITICAL", short_msg => $output_error . $output);
    }
    else {
	$self->{output}->output_add(severity => "OK", short_msg => "No orphan resource found\n" . $output);
    }
}

1;

__END__

=head1 MODE

Check orphan resources.

Since there are multiple calls to multiple Rest APIs versions, api-version parameter is hardcoded in the mode code.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --custommode=api --mode=orphan-resource
{--resource-group='MYRESOURCEGROUP'] --exclude-name='MyDisk|DataDisk.*' [--no-managed-disks] [--no-nics] [--no-nsgs] [--no-public-ips] [--no-route-tables] [--no-snapshots]


=over 8

=item B<--resource-group>

Set resource group (Required).

=item B<--exclude-name>

Exclude resource from check (Can be a regexp).

=item B--no-managed-disks --no-nics --no-nsgs --no-public-ips --no-route-tables --no-snapshots

Exclude resource type from check

=back

=cut
