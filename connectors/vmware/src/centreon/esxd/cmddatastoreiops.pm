
package centreon::esxd::cmddatastoreiops;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'datastoreiops';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

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
    $self->{manager} = centreon::esxd::common::init_response();
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
    if (defined($self->{datastore_name}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{datastore_name}\E$/;
    } elsif (!defined($self->{datastore_name})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{datastore_name}/;
    }
    my @properties = ('summary.accessible', 'summary.name', 'vm', 'info');
    my $result = centreon::esxd::common::search_entities(command => $self, view_type => 'Datastore', properties => \@properties, filter => \%filters);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All Datastore IOPS counters are ok"));
    }
    
    #my %uuid_list = ();
    my %disk_name = ();
    my %datastore_lun = ();
    my $ds_checked = 0;
    foreach (@$result) {
        next if (centreon::esxd::common::datastore_state(connector => $self->{connector},
                                                         name => $_->{'summary.name'}, 
                                                         state => $_->{'summary.accessible'},
                                                         status => $self->{disconnect_status},
                                                         multiple => $multiple) == 0);
    
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
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "No Vmfs datastore(s) checked. Cannot get iops from Nas datastore(s)");
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

    @properties = ('name', 'runtime.connectionState', 'runtime.powerState');
    my $result2 = centreon::esxd::common::get_views($self->{connector}, \@vm_array, \@properties);
    return if (!defined($result2));
    
    # Remove disconnected or not running vm
    my %ref_ids_vm = ();
    for(my $i = $#{$result2}; $i >= 0; --$i) {
        if (!centreon::esxd::common::is_connected(state => ${$result2}[$i]->{'runtime.connectionState'}->val) || 
            !centreon::esxd::common::is_running(power => ${$result2}[$i]->{'runtime.powerState'}->val)) {
            splice @$result2, $i, 1;
            next;
        }
        $ref_ids_vm{${$result2}[$i]->{mo_ref}->{value}} = ${$result2}[$i]->{name};
    }

    # Vsphere >= 4.1
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{connector},
                        $result2, 
                        [{'label' => 'disk.numberRead.summation', 'instances' => ['*']},
                        {'label' => 'disk.numberWrite.summation', 'instances' => ['*']}],
                        $self->{connector}->{perfcounter_speriod},
                        skip_undef_counter => 1, multiples => 1);                  
    
    return if (centreon::esxd::common::performance_errors($self->{connector}, $values) == 1);

    foreach (keys %$values) {
        my ($vm_id, $id, $disk_name) = split(/:/);
        
        # RDM Disk. We skip. Don't know how to manage it right now.
        next if (!defined($disk_name{$disk_name}));
        
        my $tmp_value = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$_}[0] /  $self->{connector}->{perfcounter_speriod}));
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
        
        my $exit = $self->{manager}->{perfdata}->threshold_check(value => $total_read_counter, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{manager}->{output}->output_add(long_msg => sprintf("'%s' read iops on '%s'", 
                                               $total_read_counter, $_));
        if ($multiple == 0 ||
            !$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
             $self->{manager}->{output}->output_add(severity => $exit,
                                                    short_msg => sprintf("'%s' read iops on '%s'", 
                                               $total_read_counter, $_));
             $self->vm_iops_details(label => 'disk.numberRead.summation', 
                                    type => 'read',
                                    detail => $datastore_lun{$_}, 
                                    ref_vm => \%ref_ids_vm);
        }
        $exit = $self->{manager}->{perfdata}->threshold_check(value => $total_write_counter, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{manager}->{output}->output_add(long_msg => sprintf("'%s' write iops on '%s'", 
                                               $total_write_counter, $_));
        if ($multiple == 0 ||
            !$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
             $self->{manager}->{output}->output_add(severity => $exit,
                                                    short_msg => sprintf("'%s' write iops on '%s'", 
                                               $total_write_counter, $_));
             $self->vm_iops_details(label => 'disk.numberWrite.summation',
                                    type => 'write',
                                    detail => $datastore_lun{$_}, 
                                    ref_vm => \%ref_ids_vm)
        }
        
        my $extra_label = '';
        $extra_label = '_' . $_ if ($multiple == 1);
        $self->{manager}->{output}->perfdata_add(label => 'riops' . $extra_label, unit => 'iops',
                                                 value => $total_read_counter,
                                                 warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                 critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                 min => 0);
        $self->{manager}->{output}->perfdata_add(label => 'wiops' . $extra_label, unit => 'iops',
                                                 value => $total_write_counter,
                                                 warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                 critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                 min => 0);
    }
}

sub vm_iops_details {
    my ($self, %options) = @_;
    
    $self->{manager}->{output}->output_add(long_msg => sprintf("  VM IOPs details: "));
    my $num = 0;
    foreach my $value (keys %{$options{detail}}) {
        # display only for high iops
        if ($value =~ /^vm.*?$options{label}$/ && $options{detail}->{$value} >= $self->{detail_iops_min}) {
            my ($vm_id) = split(/_/, $value);
            $num++;
            $self->{manager}->{output}->output_add(long_msg => sprintf("    '%s' %s iops", $options{ref_vm}->{$vm_id}, $options{detail}->{$value})); 
        }
    }
    
    if ($num == 0) {
        $self->{manager}->{output}->output_add(long_msg => sprintf("    no vm with iops >= %s", $self->{detail_iops_min}));
    }
}

1;
