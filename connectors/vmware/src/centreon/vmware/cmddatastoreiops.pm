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

package centreon::vmware::cmddatastoreiops;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'datastoreiops';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

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

    my $filters = $self->build_filter(label => 'name', search_option => 'datastore_name', is_regexp => 'filter');
    my @properties = ('summary.accessible', 'summary.name', 'summary.type', 'vm', 'info');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'Datastore', properties => \@properties, filter => $filters);
    return if (!defined($result));

    my $ds_vsan = {};

    my $data = {};
    #my %uuid_list = ();
    my %disk_name = ();
    my %datastore_lun = ();
    my $ds_checked = 0;
    foreach (@$result) {
        $data->{$_->{'summary.name'}} = { name => $_->{'summary.name'}, accessible => $_->{'summary.accessible'}, type => $_->{'summary.type'} };
        next if (centreon::vmware::common::is_accessible(accessible => $_->{'summary.accessible'}) == 0);

        if ($_->{'summary.type'} eq 'vsan') {
            $ds_vsan->{$_->{mo_ref}->{value}} = $_->{'summary.name'};
            $ds_checked = 1;
        }
        if ($_->info->isa('VmfsDatastoreInfo')) {
            #$uuid_list{$_->volume->uuid} = $_->volume->name;
            # Not need. We are on Datastore level (not LUN level)
            $ds_checked = 1;
            foreach my $extent (@{$_->info->vmfs->extent}) {
                $disk_name{$extent->diskName} = $_->info->vmfs->name;
                if (!defined($datastore_lun{$_->info->vmfs->name})) {
                    %{$datastore_lun{$_->info->vmfs->name}} = ('disk.numberRead.summation' => 0, 'disk.numberWrite.summation'  => 0);
                }
            }
        }
        #if ($_->info->isa('NasDatastoreInfo')) {
            # Zero disk Info
        #}
    }

    if ($ds_checked == 0) {
        centreon::vmware::common::set_response(code => 100, short_message => "No Vmfs datastore(s) checked. Cannot get iops from Nas datastore(s)");
        return ;
    }

    my @vm_array = ();
    my %added_vm = ();
    foreach my $entity_view (@$result) {
        if (defined($entity_view->vm)) {
            foreach (@{$entity_view->vm}) {
                next if (defined($added_vm{$_->{value}}));
                push @vm_array, $_;
                $added_vm{$_->{value}} = 1;
            }
        }
    }
    
    if (scalar(@vm_array) == 0) {
        centreon::vmware::common::set_response(code => 200, short_message => "No virtual machines on the datastore");
        return ;
    }

    @properties = ('name', 'summary.config.instanceUuid', 'runtime.connectionState', 'runtime.powerState');
    my $result2 = centreon::vmware::common::get_views($self->{connector}, \@vm_array, \@properties);
    return if (!defined($result2));

    # Remove disconnected or not running vm
    my ($moref_vm, $uuid_vm) = ({}, {});
    for(my $i = $#{$result2}; $i >= 0; --$i) {
        if (!centreon::vmware::common::is_connected(state => $result2->[$i]->{'runtime.connectionState'}->val) || 
            !centreon::vmware::common::is_running(power => $result2->[$i]->{'runtime.powerState'}->val)) {
            splice @$result2, $i, 1;
            next;
        }

        $uuid_vm->{$result2->[$i]->{'summary.config.instanceUuid'}} = $result2->[$i]->{mo_ref}->{value};
        $moref_vm->{$result2->[$i]->{mo_ref}->{value}} = $result2->[$i]->{name};
    }
    
    if (scalar(@{$result2}) == 0) {
        centreon::vmware::common::set_response(code => 200, short_message => "No active virtual machines on the datastore");
        return ;
    }

    my $interval_sec = $self->{connector}->{perfcounter_speriod};
    if (defined($self->{sampling_period}) && $self->{sampling_period} ne '') {
        $interval_sec = $self->{sampling_period};
    }

    # VSAN part
    if ($self->is_vsan_enabled() && scalar(keys(%$ds_vsan)) > 0) {
        my $vsan_performance_mgr = centreon::vmware::common::vsan_create_mo_view(
            vsan_vim => $self->{connector}->{vsan_vim},
            type => 'VsanPerformanceManager',
            value => 'vsan-performance-manager',
        );
        my $cluster_views = centreon::vmware::common::search_entities(command => $self, view_type => 'ComputeResource', properties => ['name', 'datastore'], filter => undef);
        my $clusters = {};
        foreach my $cluster_view (@$cluster_views) {
            $clusters->{$cluster_view->{name}} = {};
            foreach (@{$cluster_view->{datastore}}) {
                if (defined($ds_vsan->{$_->{value}})) {
                    $clusters->{$cluster_view->{name}}->{ds_vsan} = $ds_vsan->{$_->{value}};
                    last;
                }
            }

            next if (!defined($clusters->{$cluster_view->{name}}->{ds_vsan}));
            my $result = centreon::vmware::common::vsan_get_performances(
                vsan_performance_mgr => $vsan_performance_mgr,
                cluster => $cluster_view,
                entityRefId => 'virtual-machine:*',
                labels => ['iopsRead', 'iopsWrite'],
                interval => $interval_sec,
                time_shift => $self->{time_shift}
            );
            
            $datastore_lun{ $clusters->{$cluster_view->{name}}->{ds_vsan} } = {
                'disk.numberRead.summation' => 0,
                'disk.numberWrite.summation' => 0,
            };
            # we recreate format: vm-{movalue}_disk.numberWrite.summation
            foreach (keys %$result) {
                next if (! /virtual-machine:(.*)/);
                next if (!defined($uuid_vm->{$1}));
                my $moref = $uuid_vm->{$1};
                $datastore_lun{ $clusters->{$cluster_view->{name}}->{ds_vsan} }->{$moref . '_disk.numberRead.summation'} = $result->{$_}->{iopsRead};
                $datastore_lun{ $clusters->{$cluster_view->{name}}->{ds_vsan} }->{$moref . '_disk.numberWrite.summation'} = $result->{$_}->{iopsWrite};
                $datastore_lun{ $clusters->{$cluster_view->{name}}->{ds_vsan} }->{'disk.numberRead.summation'} += $result->{$_}->{iopsRead};
                $datastore_lun{ $clusters->{$cluster_view->{name}}->{ds_vsan} }->{'disk.numberWrite.summation'} += $result->{$_}->{iopsWrite};
            }
        }
    }

    # Vsphere >= 4.1
    my $values = centreon::vmware::common::generic_performance_values_historic(
        $self->{connector},
        $result2, 
        [
            { label => 'disk.numberRead.summation', instances => ['*'] },
            { label => 'disk.numberWrite.summation', instances => ['*'] }
        ],
        $self->{connector}->{perfcounter_speriod},
        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
        skip_undef_counter => 1, multiples => 1
    );                  
    
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);

    foreach (keys %$values) {
        my ($vm_id, $id, $disk_name) = split(/:/);
        
        # RDM Disk. We skip. Don't know how to manage it right now.
        next if (!defined($disk_name{$disk_name}));
        
        my $tmp_value = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$_} / $interval_sec));
        $datastore_lun{$disk_name{$disk_name}}{$self->{connector}->{perfcounter_cache_reverse}->{$id}} += $tmp_value;
        if (!defined($datastore_lun{$disk_name{$disk_name}}{$vm_id . '_' . $self->{connector}->{perfcounter_cache_reverse}->{$id}})) {
            $datastore_lun{$disk_name{$disk_name}}{$vm_id . '_' . $self->{connector}->{perfcounter_cache_reverse}->{$id}} = $tmp_value;
        } else {
            $datastore_lun{$disk_name{$disk_name}}{$vm_id . '_' . $self->{connector}->{perfcounter_cache_reverse}->{$id}} += $tmp_value;
        }
    }
    
    foreach (keys %datastore_lun) {
        my $total_read_counter = $datastore_lun{$_}{'disk.numberRead.summation'};
        my $total_write_counter = $datastore_lun{$_}{'disk.numberWrite.summation'};
        
        $data->{$_}->{'disk.numberRead.summation'} = $total_read_counter;
        $data->{$_}->{'disk.numberWrite.summation'} = $total_write_counter;
        $data->{$_}->{vm} = {};
        
        $self->vm_iops_details(
            label => 'disk.numberRead.summation', 
            type => 'read',
            detail => $datastore_lun{$_}, 
            ref_vm => $moref_vm,
            data_vm => $data->{$_}->{vm}
        );
        $self->vm_iops_details(
            label => 'disk.numberWrite.summation', 
            type => 'write',
            detail => $datastore_lun{$_}, 
            ref_vm => $moref_vm,
            data_vm => $data->{$_}->{vm}
        );
    }
    
    centreon::vmware::common::set_response(data => $data);
}

sub vm_iops_details {
    my ($self, %options) = @_;
    
    foreach my $value (keys %{$options{detail}}) {
        # display only for high iops
        if ($value =~ /^vm.*?$options{label}$/ && $options{detail}->{$value} >= $self->{detail_iops_min}) {
            my ($vm_id) = split(/_/, $value);
            $options{data_vm}->{$options{ref_vm}->{$vm_id}} = {} if (!defined($options{data_vm}->{$options{ref_vm}->{$vm_id}}));
            $options{data_vm}->{$options{ref_vm}->{$vm_id}}->{$options{label}} = $options{detail}->{$value};
        }
    }
}

1;
