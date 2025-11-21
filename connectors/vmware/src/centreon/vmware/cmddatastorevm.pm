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

package centreon::vmware::cmddatastorevm;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;
use File::Basename;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'datastorevm';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{vm_hostname}) && $options{arguments}->{vm_hostname} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: vm hostname cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{datastore_name}) && $options{arguments}->{datastore_name} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: datastore name cannot be null");
        return 1;
    }
    
    return 0;
}

sub run {
    my $self = shift;

    if (!($self->{connector}->{perfcounter_speriod} > 0)) {
        centreon::vmware::common::set_response(code => -1, short_message => "Can't retrieve perf counters");
        return ;
    }

    my $multiple = 0;
    my $filters = $self->build_filter(label => 'name', search_option => 'vm_hostname', is_regexp => 'filter');
    $self->add_filter(filters => $filters, label => 'config.annotation', search_option => 'filter_description');
    $self->add_filter(filters => $filters, label => 'config.guestFullName', search_option => 'filter_os');
    $self->add_filter(filters => $filters, label => 'config.uuid', search_option => 'filter_uuid');
    
    my @properties = ('name', 'datastore', 'runtime.connectionState', 'runtime.powerState');
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    my $ds_regexp;
    if (defined($self->{datastore_name}) && !defined($self->{filter_datastore})) {
        $ds_regexp = qr/^\Q$self->{datastore_name}\E$/;
    } elsif (!defined($self->{datastore_name})) {
        $ds_regexp = qr/.*/;
    } else {
        $ds_regexp = qr/$self->{datastore_name}/;
    }

    my $data = {};
    my $mapped_datastore = {};
    my @ds_array = ();
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};

        $data->{$entity_value} = {
            name => $entity_view->{name},
            connection_state => $entity_view->{'runtime.connectionState'}->val, 
            power_state => $entity_view->{'runtime.powerState'}->val,
            'config.annotation' => defined($entity_view->{'config.annotation'}) ? $entity_view->{'config.annotation'} : undef,
            datastore => {},
        };
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);
        next if (centreon::vmware::common::is_running(power => $entity_view->{'runtime.powerState'}->val) == 0);

        if (defined($entity_view->datastore)) {
            foreach (@{$entity_view->datastore}) {                
                if (!defined($mapped_datastore->{$_->value})) {
                    push @ds_array, $_;
                    $mapped_datastore->{$_->value} = 1;
                }
            }
        }
    }

    if (scalar(@ds_array) == 0) {
        centreon::vmware::common::set_response(code => 200, short_message => "no virtual machines running or no datastore found");
        return ;
    }

    @properties = ('info');
    my $result2 = centreon::vmware::common::get_views($self->{connector}, \@ds_array, \@properties);
    return if (!defined($result2));
    
    #my %uuid_list = ();
    my %disk_name = ();
    my %datastore_lun = ();    
    foreach (@$result2) {
        if ($_->info->isa('VmfsDatastoreInfo')) {
            #$uuid_list{$_->volume->uuid} = $_->volume->name;
            # Not need. We are on Datastore level (not LUN level)
            foreach my $extent (@{$_->info->vmfs->extent}) {
                $disk_name{$extent->diskName} = $_->info->vmfs->name;
            }
        }
        #if ($_->info->isa('NasDatastoreInfo')) {
            # Zero disk Info
        #}
    }    
    
    # Vsphere >= 4.1
    # We don't filter. To filter we'll need to get disk from vms
    my $values = centreon::vmware::common::generic_performance_values_historic($self->{connector},
                        $result, 
                        [{label => 'disk.numberRead.summation', instances => ['*']},
                        {label => 'disk.numberWrite.summation', instances => ['*']},
                        {label => 'disk.maxTotalLatency.latest', instances => ['']}],
                        $self->{connector}->{perfcounter_speriod},
                        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);
    
    my $interval_sec = $self->{connector}->{perfcounter_speriod};
    if (defined($self->{sampling_period}) && $self->{sampling_period} ne '') {
        $interval_sec = $self->{sampling_period};
    }
 
    my $finded = 0;
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0 &&
                 centreon::vmware::common::is_running(power => $entity_view->{'runtime.powerState'}->val) == 0);
        
        my %datastore_lun = ();
        foreach (keys %{$values->{$entity_value}}) {
            my ($id, $disk_name) = split /:/;
        
            # RDM Disk. We skip. Don't know how to manage it right now.
            next if (!defined($disk_name{$disk_name}));
            # We skip datastore not filtered
            next if ($disk_name{$disk_name} !~ /$ds_regexp/); 
            $datastore_lun{$disk_name{$disk_name}} = { 'disk.numberRead.summation' => 0, 
                                                       'disk.numberWrite.summation' => 0 } if (!defined($datastore_lun{$disk_name{$disk_name}}));
            $datastore_lun{$disk_name{$disk_name}}->{$self->{connector}->{perfcounter_cache_reverse}->{$id}} += $values->{$entity_value}->{$_};
        }

        foreach (sort keys %datastore_lun) {
            my $read_counter = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($datastore_lun{$_}{'disk.numberRead.summation'} / $interval_sec));
            my $write_counter = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($datastore_lun{$_}{'disk.numberWrite.summation'} / $interval_sec));

            $data->{$entity_value}->{datastore}->{$_} = {
                'disk.numberRead.summation' => $read_counter,
                'disk.numberWrite.summation' => $write_counter,
            };
        }
        
        my $max_total_latency = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'disk.maxTotalLatency.latest'}->{key} . ":"}));
        $data->{$entity_value}->{'disk.maxTotalLatency.latest'} = $max_total_latency;
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
