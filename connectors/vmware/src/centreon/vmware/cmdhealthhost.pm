# Copyright 2015 Centreon (http://www.centreon.com/)
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

package centreon::vmware::cmdhealthhost;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'healthhost';
    
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
    my @properties = ('name', 'runtime.healthSystemRuntime.hardwareStatusInfo', 'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo', 
                      'runtime.connectionState');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        $data->{$entity_value} = { name => $entity_view->{name}, state => $entity_view->{'runtime.connectionState'}->val };
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);

        my $cpuStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{cpuStatusInfo};
        my $memoryStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{memoryStatusInfo};
        my $storageStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{storageStatusInfo};
        my $numericSensorInfo = $entity_view->{'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo'};
        
        # CPU
        if (defined($cpuStatusInfo)) {
            $data->{$entity_value}->{cpu_info} = { ok => 0, yellow => 0, red => 0, summary_red => [], summary_yellow => [] };
            foreach (@$cpuStatusInfo) {
                if ($_->status->key =~ /^red$/i) {
                    push @{$data->{$entity_value}->{cpu_info}->{summary_red}}, { name => $_->name, summary => $_->status->summary };
                    $data->{$entity_value}->{cpu_info}->{red}++;
                } elsif ($_->status->key =~ /^yellow$/i) {
                    push @{$data->{$entity_value}->{cpu_info}->{summary_yellow}}, { name => $_->name, summary => $_->status->summary };
                    $data->{$entity_value}->{cpu_info}->{yellow}++;
                } else {
                    $data->{$entity_value}->{cpu_info}->{ok}++;
                }
            }
        }
        
        # Memory
        if (defined($memoryStatusInfo)) {
            $data->{$entity_value}->{memory_info} = { ok => 0, yellow => 0, red => 0, summary_red => [], summary_yellow => [] };
            foreach (@$memoryStatusInfo) {
                if ($_->status->key =~ /^red$/i) {
                    push @{$data->{$entity_value}->{memory_info}->{summary_red}}, { name => $_->name, summary => $_->status->summary };
                    $data->{$entity_value}->{memory_info}->{red}++;
                } elsif ($_->status->key =~ /^yellow$/i) {
                    push @{$data->{$entity_value}->{memory_info}->{summary_yellow}}, { name => $_->name, summary => $_->status->summary };
                    $data->{$entity_value}->{memory_info}->{yellow}++;
                } else {
                    $data->{$entity_value}->{memory_info}->{ok}++;
                }
            }
        }
        
        # Storage
        if (defined($self->{storage_status}) && defined($storageStatusInfo)) {
            $data->{$entity_value}->{storage_info} = { ok => 0, yellow => 0, red => 0, summary_red => [], summary_yellow => [] };
            foreach (@$storageStatusInfo) {
                if ($_->status->key =~ /^red$/i) {
                    push @{$data->{$entity_value}->{storage_info}->{summary_red}}, { name => $_->name, summary => $_->status->summary };
                    $data->{$entity_value}->{storage_info}->{red}++;
                } elsif ($_->status->key =~ /^yellow$/i) {
                    push @{$data->{$entity_value}->{storage_info}->{summary_yellow}}, { name => $_->name, summary => $_->status->summary };
                    $data->{$entity_value}->{storage_info}->{yellow}++;
                } else {
                    $data->{$entity_value}->{storage_info}->{ok}++;
                }
            }
        }
        
        # Sensor
        if (defined($numericSensorInfo)) {
            $data->{$entity_value}->{sensor_info} = { ok => 0, yellow => 0, red => 0, summary_red => [], summary_yellow => [] };
            foreach (@$numericSensorInfo) {
                if ($_->healthState->key =~ /^red$/i) {
                    push @{$data->{$entity_value}->{sensor_info}->{summary_red}}, { type => $_->sensorType, name => $_->name, summary => $_->healthState->summary };
                    $data->{$entity_value}->{sensor_info}->{red}++;
                } elsif ($_->healthState->key =~ /^yellow$/i) {
                    push @{$data->{$entity_value}->{sensor_info}->{summary_yellow}}, { type => $_->sensorType, name => $_->name, summary => $_->healthState->summary };
                    $data->{$entity_value}->{sensor_info}->{yellow}++;
                } else {
                    $data->{$entity_value}->{sensor_info}->{ok}++;
                }
            }
        }
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
