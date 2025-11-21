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

package centreon::vmware::cmdlimitvm;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'limitvm';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{vm_hostname}) && $options{arguments}->{vm_hostname} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: vm hostname cannot be null");
        return 1;
    }

    return 0;
}

sub run {
    my $self = shift;

    my $filters = $self->build_filter(label => 'name', search_option => 'vm_hostname', is_regexp => 'filter');
    $self->add_filter(filters => $filters, label => 'config.annotation', search_option => 'filter_description');
    $self->add_filter(filters => $filters, label => 'config.guestFullName', search_option => 'filter_os');
    $self->add_filter(filters => $filters, label => 'config.uuid', search_option => 'filter_uuid');
    
    my @properties = ('name', 'runtime.connectionState', 'runtime.powerState', 'config.cpuAllocation.limit', 'config.memoryAllocation.limit');
    if (defined($self->{check_disk_limit})) {
         push @properties, 'config.hardware.device';
    }
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }

    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};

        $data->{$entity_value} = {
            name => $entity_view->{name},
            connection_state => $entity_view->{'runtime.connectionState'}->val, 
            power_state => $entity_view->{'runtime.powerState'}->val,
            'config.annotation' => defined($entity_view->{'config.annotation'}) ? $entity_view->{'config.annotation'} : undef,
            'config.cpuAllocation.limit' => -1,
            'config.memoryAllocation.limit' => -1,
            'config.storageIOAllocation.limit' => [],
        };
        
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);

        # CPU Limit
        if (defined($entity_view->{'config.cpuAllocation.limit'}) && $entity_view->{'config.cpuAllocation.limit'} != -1) {
            $data->{$entity_value}->{'config.cpuAllocation.limit'} = $entity_view->{'config.cpuAllocation.limit'};
        }
        
        # Memory Limit
        if (defined($entity_view->{'config.memoryAllocation.limit'}) && $entity_view->{'config.memoryAllocation.limit'} != -1) {
            $data->{$entity_value}->{'config.memoryAllocation.limit'} = $entity_view->{'config.memoryAllocation.limit'};
        }
        
        # Disk
        if (defined($self->{check_disk_limit})) {
            foreach my $device (@{$entity_view->{'config.hardware.device'}}) {
                if ($device->isa('VirtualDisk')) {
                    if (defined($device->storageIOAllocation->limit) && $device->storageIOAllocation->limit != -1) {
                        push @{$data->{$entity_value}->{'config.storageIOAllocation.limit'}}, { name => $device->backing->fileName, limit => $device->storageIOAllocation->limit };
                    }
                }
            }
        }
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
