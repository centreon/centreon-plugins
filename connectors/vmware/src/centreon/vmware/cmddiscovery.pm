#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package centreon::vmware::cmddiscovery;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;

    $self->{commandName} = 'discovery';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;
    
    if (defined($options{arguments}->{resource_type}) && $options{arguments}->{resource_type} !~ /^vm$|^esx$/) {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: resource type must be 'vm' or 'esx'");
        return 1;
    }

    $self->{resource_type} = $options{arguments}->{resource_type} if (defined($options{arguments}->{resource_type}));

    return 0;
}

sub run {
    my $self = shift;
    
    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my $filters = $self->build_filter(label => 'name', search_option => 'datacenter', is_regexp => 'filter');
    my @properties = ('name', 'hostFolder');

    my $datacenters = centreon::vmware::common::search_entities(command => $self, view_type => 'Datacenter', properties => \@properties, filter => $filters);
    return if (!defined($datacenters));

    foreach my $datacenter (@{$datacenters}) {
        my @properties = ('childType', 'childEntity');

        my @array;
        if (defined $datacenter->hostFolder) {
            push @array, $datacenter->hostFolder;
        }

        my $childs = centreon::vmware::common::get_views($self->{connector}, \@array, \@properties);
        next if (!defined($childs));

        foreach my $child (@{$childs}) {
            my %types = map { $_ => 1 } @{$child->childType};
            next if (!defined($types{ComputeResource}));
            my @properties = ('name', 'host');
        
            my $clusters = centreon::vmware::common::get_views($self->{connector}, \@{$child->childEntity}, \@properties);
            next if (!defined($clusters));

            foreach my $cluster (@{$clusters}) {
                my @properties = ('name', 'vm', 'config.virtualNicManagerInfo.netConfig', 'config.product.version',
                    'config.product.productLineId', 'hardware.systemInfo.vendor', 'hardware.systemInfo.model',
                    'hardware.systemInfo.uuid', 'runtime.powerState', 'runtime.inMaintenanceMode', 'runtime.connectionState');
                
                my $esxs = centreon::vmware::common::get_views($self->{connector}, \@{$cluster->host}, \@properties);
                next if (!defined($esxs));

                foreach my $esx (@{$esxs}) {
                    my %esx;
                    
                    $esx{type} = "esx";
                    $esx{name} = $esx->name;
                    $esx{os} = $esx->{'config.product.productLineId'} . ' ' . $esx->{'config.product.version'};
                    $esx{hardware} = $esx->{'hardware.systemInfo.vendor'} . ' ' . $esx->{'hardware.systemInfo.model'};
                    $esx{power_state} = $esx->{'runtime.powerState'}->val;
                    $esx{connection_state} = $esx->{'runtime.connectionState'}->val;
                    $esx{maintenance} = $esx->{'runtime.inMaintenanceMode'};
                    $esx{datacenter} = $datacenter->name;
                    $esx{cluster} = $cluster->name;

                    foreach my $nic (@{$esx->{'config.virtualNicManagerInfo.netConfig'}}) {
                        my %lookup = map { $_->{'key'} => $_->{'spec'}->{'ip'}->{'ipAddress'} } @{$nic->{'candidateVnic'}};
                        foreach my $vnic (@{$nic->{'selectedVnic'}}) {
                            push @{$esx{'ip_' . $nic->{'nicType'}}}, $lookup{$vnic};
                        }
                    }
                    
                    push @disco_data, \%esx if ($self->{resource_type} eq 'esx');
                    next if ($self->{resource_type} ne 'vm');

                    @properties = ('config.name', 'config.annotation', 'config.template', 'config.uuid', 'config.version',
                        'config.guestId', 'guest.guestState', 'guest.hostName', 'guest.ipAddress', 'runtime.powerState');

                    my $vms = centreon::vmware::common::get_views($self->{connector}, \@{$esx->vm}, \@properties);
                    next if (!defined($vms));
                
                    foreach my $vm (@{$vms}) {
                        my %vm;
                        
                        $vm{type} = "vm";
                        $vm{name} = $vm->{'config.name'};
                        $vm{annotation} = $vm->{'config.annotation'};
                        $vm{os} = $vm->{'config.guestId'};
                        $vm{hardware} = $vm->{'config.version'};
                        $vm{guest_name} = $vm->{'guest.hostName'};
                        $vm{guest_ip} = $vm->{'guest.ipAddress'};
                        $vm{guest_state} = $vm->{'guest.guestState'};
                        $vm{power_state} = $vm->{'runtime.powerState'}->val;
                        $vm{datacenter} = $datacenter->name;
                        $vm{cluster} = $cluster->name;
                        $vm{esx} = $esx->name;
                            
                        push @disco_data, \%vm;
                    }
                }
            }
        }
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;
    
    centreon::vmware::common::set_response(data => $disco_stats);
}

1;
