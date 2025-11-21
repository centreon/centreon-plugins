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

package centreon::vmware::cmddatastorehost;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use File::Basename;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'datastorehost';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: esx hostname cannot be null");
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

    my $filters = $self->build_filter(label => 'name', search_option => 'esx_hostname', is_regexp => 'filter');
    my @properties = ('name', 'config.fileSystemVolume.mountInfo', 'runtime.connectionState');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    my %uuid_list = ();
    #my %disk_name = ();
    my $query_perfs = [];
    my $ds_regexp;
    if (defined($self->{datastore_name}) && !defined($self->{filter_datastore})) {
        $ds_regexp = qr/^\Q$self->{datastore_name}\E$/;
    } elsif (!defined($self->{datastore_name})) {
        $ds_regexp = qr/.*/;
    } else {
        $ds_regexp = qr/$self->{datastore_name}/;
    }
    
    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        $data->{$entity_value} = { name => $entity_view->{name}, state => $entity_view->{'runtime.connectionState'}->val, datastore => {} };
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);
                                                 
        my $instances = [];
        foreach (@{$entity_view->{'config.fileSystemVolume.mountInfo'}}) {
            if ($_->volume->isa('HostVmfsVolume')) {
                next if ($_->volume->name !~ /$ds_regexp/);
                
                $uuid_list{$_->volume->uuid} = $_->volume->name;
                push @$instances, $_->volume->uuid;
                # Not need. We are on Datastore level (not LUN level)
                #foreach my $extent (@{$_->volume->extent}) {
                #    $disk_name{$extent->diskName} = $_->volume->name;
                #}
            }
            if ($_->volume->isa('HostNasVolume')) {
                next if ($_->volume->name !~ /$ds_regexp/);

                $uuid_list{basename($_->mountInfo->path)} = $_->volume->name;
                push @$instances, basename($_->mountInfo->path);
            }
        }
        
        if (scalar(@$instances) > 0) {
            push @$query_perfs, {
                entity => $entity_view,
                metrics => [ 
                    { label => 'datastore.totalReadLatency.average', instances => $instances },
                    { label => 'datastore.totalWriteLatency.average', instances => $instances }
                ]
            };
        }
    }
    
    if (scalar(@$query_perfs) == 0) {
        centreon::vmware::common::set_response(code => 100, short_message => "Can't get a single datastore.");
        return ;
    }

    # Vsphere >= 4.1
    # You get counters even if datastore is disconnect...
    my $values = centreon::vmware::common::generic_performance_values_historic($self->{connector},
                        undef, 
                        $query_perfs,
                        $self->{connector}->{perfcounter_speriod},
                        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);

    foreach my $entity_view (@$result) {
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);
        my $entity_value = $entity_view->{mo_ref}->{value};

        my $checked = {};
        foreach (keys %{$values->{$entity_value}}) {
            my ($id, $uuid) = split /:/;
            next if (defined($checked->{$uuid}));
            $checked->{$uuid} = 1;
            
            my $read_counter = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'datastore.totalReadLatency.average'}->{'key'} . ":" . $uuid}));
            my $write_counter = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'datastore.totalWriteLatency.average'}->{'key'} . ":" . $uuid}));
            
            $data->{$entity_value}->{datastore}->{$uuid_list{$uuid}} = {
                'datastore.totalReadLatency.average' => $read_counter,
                'datastore.totalWriteLatency.average' => $write_counter,
            };
        }
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
