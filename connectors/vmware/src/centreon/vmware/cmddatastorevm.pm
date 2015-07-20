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

package centreon::vmware::cmddatastorevm;

use strict;
use warnings;
use centreon::vmware::common;
use File::Basename;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'datastorevm';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{vm_hostname}) && $options{arguments}->{vm_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: vm hostname cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{datastore_name}) && $options{arguments}->{datastore_name} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: datastore name cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{disconnect_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{disconnect_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for disconnect status '" . $options{arguments}->{disconnect_status} . "'");
        return 1;
    }
    if (defined($options{arguments}->{nopoweredon_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{nopoweredon_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for nopoweredon status '" . $options{arguments}->{nopoweredon_status} . "'");
        return 1;
    }
    foreach my $label (('warning', 'critical')) {
        if (($options{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label})) == 0) {
            $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                    short_msg => "Argument error: wrong value for $label value '" . $options{arguments}->{$label} . "'.");
            return 1;
        }
    }
    return 0;
}

sub initArgs {
    my ($self, %options) = @_;
    
    foreach (keys %{$options{arguments}}) {
        $self->{$_} = $options{arguments}->{$_};
    }
    $self->{manager} = centreon::vmware::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
    foreach my $label (('warning', 'critical')) {
        $self->{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label});
    }
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;

    if (!($self->{connector}->{perfcounter_speriod} > 0)) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Can't retrieve perf counters");
        return ;
    }

    my %filters = ();
    my $multiple = 0;
    if (defined($self->{vm_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{vm_hostname}\E$/;
    } elsif (!defined($self->{vm_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{vm_hostname}/;
    }
    if (defined($self->{filter_description}) && $self->{filter_description} ne '') {
        $filters{'config.annotation'} = qr/$self->{filter_description}/;
    }
    
    my @properties = ('name', 'datastore', 'runtime.connectionState', 'runtime.powerState');
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => \%filters);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    my $ds_regexp;
    if (defined($self->{datastore_name}) && !defined($self->{filter_datastore})) {
        $ds_regexp = qr/^\Q$self->{datastore_name}\E$/;
    } elsif (!defined($self->{datastore_name})) {
        $ds_regexp = qr/.*/;
    } else {
        $ds_regexp = qr/$self->{datastore_name}/;
    }

    my $mapped_datastore = {};
    my @ds_array = ();
    foreach my $entity_view (@$result) {
         next if (centreon::vmware::common::vm_state(connector => $self->{connector},
                                                  hostname => $entity_view->{name}, 
                                                  state => $entity_view->{'runtime.connectionState'}->val,
                                                  power => $entity_view->{'runtime.powerState'}->val,
                                                  status => $self->{disconnect_status},
                                                  powerstatus => $self->{nopoweredon_status},
                                                  multiple => $multiple) == 0);
        if (defined($entity_view->datastore)) {
            foreach (@{$entity_view->datastore}) {                
                if (!defined($mapped_datastore->{$_->value})) {
                    push @ds_array, $_;
                    $mapped_datastore->{$_->value} = 1;
                }
            }
        }
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
                        [{'label' => 'disk.numberRead.summation', 'instances' => ['*']},
                        {'label' => 'disk.numberWrite.summation', 'instances' => ['*']}],
                        $self->{connector}->{perfcounter_speriod},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);

    $self->{manager}->{output}->output_add(severity => 'OK',
                                           short_msg => sprintf("All Datastore IOPS counters are ok"));
    my $finded = 0;
    foreach my $entity_view (@$result) {
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0 &&
                 centreon::vmware::common::is_running(power => $entity_view->{'runtime.powerState'}->val) == 0);
        my $entity_value = $entity_view->{mo_ref}->{value};
        my $prefix_msg = "'$entity_view->{name}'";
        if (defined($self->{display_description}) && defined($entity_view->{'config.annotation'}) &&
            $entity_view->{'config.annotation'} ne '') {
            $prefix_msg .= ' [' . centreon::vmware::common::strip_cr(value => $entity_view->{'config.annotation'}) . ']';
        }
        
        $finded |= 1;
        my %datastore_lun = ();
        foreach (keys %{$values->{$entity_value}}) {
            my ($id, $disk_name) = split /:/;
        
            # RDM Disk. We skip. Don't know how to manage it right now.
            next if (!defined($disk_name{$disk_name}));
            # We skip datastore not filtered
            next if ($disk_name{$disk_name} !~ /$ds_regexp/); 
            $datastore_lun{$disk_name{$disk_name}} = { 'disk.numberRead.summation' => 0, 
                                                       'disk.numberWrite.summation' => 0 } if (!defined($datastore_lun{$disk_name{$disk_name}}));
            $datastore_lun{$disk_name{$disk_name}}->{$self->{connector}->{perfcounter_cache_reverse}->{$id}} += $values->{$entity_value}->{$_}[0];
        }

        foreach (sort keys %datastore_lun) {
            $finded |= 2;
            my $read_counter = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($datastore_lun{$_}{'disk.numberRead.summation'} / $self->{connector}->{perfcounter_speriod}));
            my $write_counter = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($datastore_lun{$_}{'disk.numberWrite.summation'} / $self->{connector}->{perfcounter_speriod}));

            my $exit = $self->{manager}->{perfdata}->threshold_check(value => $read_counter, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            $self->{manager}->{output}->output_add(long_msg => sprintf("%s read iops on '%s' is %s", 
                                                   $prefix_msg, $_, $read_counter));
            if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                 $self->{manager}->{output}->output_add(severity => $exit,
                                                        short_msg => sprintf("%s read iops on '%s' is %s", 
                                                   $prefix_msg, $_, $read_counter));
            }
            $exit = $self->{manager}->{perfdata}->threshold_check(value => $write_counter, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            $self->{manager}->{output}->output_add(long_msg => sprintf("%s write iops on '%s' is %s", 
                                                   $prefix_msg, $_, $write_counter));
            if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                 $self->{manager}->{output}->output_add(severity => $exit,
                                                        short_msg => sprintf("%s write iops on '%s' is %s", 
                                                   $prefix_msg, $_, $write_counter));
            }
            
            my $extra_label = '';
            $extra_label = '_' . $entity_view->{name} if ($multiple == 1);
            $self->{manager}->{output}->perfdata_add(label => 'riops' . $extra_label . '_' . $_, unit => 'iops',
                                                     value => $read_counter,
                                                     warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                     critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                     min => 0);
            $self->{manager}->{output}->perfdata_add(label => 'wiops' . $extra_label . '_' . $_, unit => 'iops',
                                                     value => $write_counter,
                                                     warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                     critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                     min => 0);
        }
    }
    
    if (($finded & 2) == 0) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Can't get a single datastore.");
    }
}

1;
