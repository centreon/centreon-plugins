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

package centreon::vmware::cmddatastorehost;

use strict;
use warnings;
use File::Basename;
use centreon::vmware::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'datastorehost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: esx hostname cannot be null");
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
    if (defined($self->{esx_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{esx_hostname}\E$/;
    } elsif (!defined($self->{esx_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{esx_hostname}/;
    }
    my @properties = ('name', 'config.fileSystemVolume.mountInfo', 'runtime.connectionState');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => \%filters);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    
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
    
    foreach my $entity_view (@$result) {
        next if (centreon::vmware::common::host_state(connector => $self->{connector},
                                                    hostname => $entity_view->{name}, 
                                                    state => $entity_view->{'runtime.connectionState'}->val,
                                                    status => $self->{disconnect_status},
                                                    multiple => $multiple) == 0);
                                                 
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
                                {label => 'datastore.totalReadLatency.average', instances => $instances},
                                {label => 'datastore.totalWriteLatency.average', instances => $instances}
                              ]
                             };
        }
    }
    
    if (scalar(@$query_perfs) == 0) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Can't get a single datastore.");
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

    $self->{manager}->{output}->output_add(severity => 'OK',
                                           short_msg => sprintf("All Datastore latencies are ok"));
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
            
            my $exit = $self->{manager}->{perfdata}->threshold_check(value => $read_counter, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            $self->{manager}->{output}->output_add(long_msg => sprintf("'%s' read on '%s' is %s ms", 
                                                   $entity_view->{name}, $uuid_list{$uuid}, $read_counter));
            if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                 $self->{manager}->{output}->output_add(severity => $exit,
                                                        short_msg => sprintf("'%s' read on '%s' is %s ms", 
                                                   $entity_view->{name}, $uuid_list{$uuid}, $read_counter));
            }
            $exit = $self->{manager}->{perfdata}->threshold_check(value => $write_counter, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            $self->{manager}->{output}->output_add(long_msg => sprintf("'%s' write on '%s' is %s ms", 
                                                   $entity_view->{name}, $uuid_list{$uuid}, $write_counter));
            if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                 $self->{manager}->{output}->output_add(severity => $exit,
                                                        short_msg => sprintf("'%s' write on '%s' is %s ms", 
                                                   $entity_view->{name}, $uuid_list{$uuid}, $write_counter));
            }
            
            my $extra_label = '';
            $extra_label = '_' . $entity_view->{name} if ($multiple == 1);
            $self->{manager}->{output}->perfdata_add(label => 'trl' . $extra_label . '_' . $uuid_list{$uuid}, unit => 'ms',
                                                     value => $read_counter,
                                                     warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                     critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                     min => 0);
            $self->{manager}->{output}->perfdata_add(label => 'twl' . $extra_label . '_' . $uuid_list{$uuid}, unit => 'ms',
                                                     value => $write_counter,
                                                     warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                     critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                     min => 0);
        }
    }
}

1;
