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
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::cmdstoragehost;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'storagehost';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: esx hostname cannot be null");
        return 1;
    }

    return 0;
}

sub run {
    my $self = shift;

    my $filters = $self->build_filter(label => 'name', search_option => 'esx_hostname', is_regexp => 'filter');
    my @properties = ('name', 'runtime.connectionState', 'runtime.inMaintenanceMode', 'configManager.storageSystem');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => $filters);
    return if (!defined($result));

    my %host_names = ();
    my @host_array = ();
    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};                          
        
        $data->{$entity_value} = {
            name => $entity_view->{name},
            state => $entity_view->{'runtime.connectionState'}->val, 
            inMaintenanceMode => $entity_view->{'runtime.inMaintenanceMode'},
        };

        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);
        next if (centreon::vmware::common::is_maintenance(maintenance => $entity_view->{'runtime.inMaintenanceMode'}) == 0);

        if (defined($entity_view->{'configManager.storageSystem'})) {
            push @host_array, $entity_view->{'configManager.storageSystem'};
            $host_names{ $entity_view->{'configManager.storageSystem'}->{value} } = $entity_value; 
        }
    }
    
    if (scalar(@host_array) == 0) {
        centreon::vmware::common::set_response(data => $data);
        return ;
    }

    @properties = ('storageDeviceInfo');
    my $result2 = centreon::vmware::common::get_views($self->{connector}, \@host_array, \@properties);
    return if (!defined($result2));
    
    foreach my $entity (@$result2) {
        my $host_id = $host_names{ $entity->{mo_ref}->{value} };

        if (defined($entity->storageDeviceInfo->hostBusAdapter)) {
            $data->{$host_id}->{adapters} = [];
            foreach my $dev (@{$entity->storageDeviceInfo->hostBusAdapter}) {
                push @{$data->{$host_id}->{adapters}}, {
                    name => $dev->device,
                    status => lc($dev->status)
                };
            }
        }

        if (defined($entity->storageDeviceInfo->scsiLun)) {
            $data->{$host_id}->{luns} = [];
            foreach my $scsi (@{$entity->storageDeviceInfo->scsiLun}) {
                my $name = $scsi->deviceName;
                if (defined($scsi->{displayName})) {
                    $name = $scsi->displayName;
                } elsif (defined($scsi->{canonicalName})) {
                    $name = $scsi->canonicalName;
                }

                push @{$data->{$host_id}->{luns}}, {
                    name => $name,
                    operational_states => $scsi->operationalState
                };
            }
        }

        if (defined($entity->storageDeviceInfo->{multipathInfo})) {
            $data->{$host_id}->{paths} = [];
            foreach my $lun (@{$entity->storageDeviceInfo->multipathInfo->lun}) {
                foreach my $path (@{$lun->path}) {
                    my $state = $path->pathState;
                    $state = $path->state if (defined($path->{state}));
                    push @{$data->{$host_id}->{paths}}, {
                        name => $path->name,
                        state => lc($state)
                    };
                }
            }
        }
    }

    centreon::vmware::common::set_response(data => $data);
}

1;
