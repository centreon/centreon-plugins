
package centreon::esxd::cmddatastoreiops;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'datastore-iops';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($ds, $filter, $warn, $crit, $details_value) = @_;

    if (!defined($ds) || $ds eq "") {
        $self->{logger}->writeLogError("ARGS error: need datastore name");
        return 1;
    }
    if (defined($details_value) && $details_value ne "" && $details_value !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: details-value must be a positive number");
        return 1;
    }
    if (defined($warn) && $warn ne "" && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be a positive number");
        return 1;
    }
    if (defined($crit) && $crit ne "" && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: crit threshold must be a positive number");
        return 1;
    }
    if (defined($warn) && defined($crit) && $warn ne "" && $crit ne "" && $warn > $crit) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be lower than crit threshold");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{ds} = $_[0];
    $self->{filter} = (defined($_[1]) && $_[1] == 1) ? 1 : 0;
    $self->{warn} = (defined($_[2]) ? $_[2] : '');
    $self->{crit} = (defined($_[3]) ? $_[3] : '');
    $self->{details_value} = (defined($_[4]) ? $_[4] : 50);
    $self->{skip_errors} = (defined($_[5]) && $_[5] == 1) ? 1 : 0;
}

sub run {
    my $self = shift;

    my $status = 0; # OK
    my $output = '';
    my $output_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output_critical = '';
    my $output_critical_append = '';
    my $output_unknown = '';
    my $output_unknown_append = '';
    my $perfdata = '';

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ();
    if ($self->{filter} == 0) {
        $filters{name} =  qr/^\Q$self->{ds}\E$/;
    } else {
        $filters{name} = qr/$self->{ds}/;
    }

    my @properties = ('summary.accessible', 'summary.name', 'vm', 'info');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    #my %uuid_list = ();
    my %disk_name = ();
    my %datastore_lun = ();
    foreach (@$result) {
        if (!centreon::esxd::common::is_accessible($_->{'summary.accessible'})) {
            if ($self->{skip_errors} == 0 || $self->{filter} == 0) {
                $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
                centreon::esxd::common::output_add(\$output_unknown, \$output_unknown_append, ", ",
                                                    "'" . $_->{'summary.name'} . "' not accessible. Can be disconnected");
            }
            next;
        }
    
        if ($_->info->isa('VmfsDatastoreInfo')) {
            #$uuid_list{$_->volume->uuid} = $_->volume->name;
            # Not need. We are on Datastore level (not LUN level)
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
    my $result2 = centreon::esxd::common::get_views($self->{obj_esxd}, \@vm_array, \@properties);
    if (!defined($result2)) {
        return ;
    }
    
    # Remove disconnected or not running vm
    my %ref_ids_vm = ();
    for(my $i = $#{$result2}; $i >= 0; --$i) {
        if (!centreon::esxd::common::is_connected(${$result2}[$i]->{'runtime.connectionState'}->val) || 
            !centreon::esxd::common::is_running(${$result2}[$i]->{'runtime.powerState'}->val)) {
            splice @$result2, $i, 1;
            next;
        }
        $ref_ids_vm{${$result2}[$i]->{mo_ref}->{value}} = ${$result2}[$i]->{name};
    }

    # Vsphere >= 4.1
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $result2, 
                        [{'label' => 'disk.numberRead.summation', 'instances' => ['*']},
                        {'label' => 'disk.numberWrite.summation', 'instances' => ['*']}],
                        $self->{obj_esxd}->{perfcounter_speriod}, 1, 1);                  
    
    return if (centreon::esxd::common::performance_errors($self->{obj_esxd}, $values) == 1);

    foreach (keys %$values) {
        my ($vm_id, $id, $disk_name) = split(/:/);
        my $tmp_value = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$_}[0] /  $self->{obj_esxd}->{perfcounter_speriod}));
        $datastore_lun{$disk_name{$disk_name}}{$self->{obj_esxd}->{perfcounter_cache_reverse}->{$id}} += $tmp_value;
        if (!defined($datastore_lun{$disk_name{$disk_name}}{$vm_id . '_' . $self->{obj_esxd}->{perfcounter_cache_reverse}->{$id}})) {
            $datastore_lun{$disk_name{$disk_name}}{$vm_id . '_' . $self->{obj_esxd}->{perfcounter_cache_reverse}->{$id}} = $tmp_value;
        } else {
            $datastore_lun{$disk_name{$disk_name}}{$vm_id . '_' . $self->{obj_esxd}->{perfcounter_cache_reverse}->{$id}} += $tmp_value;
        }
    }
    
    foreach (keys %datastore_lun) {
        my $total_read_counter = $datastore_lun{$_}{'disk.numberRead.summation'};
        my $total_write_counter = $datastore_lun{$_}{'disk.numberWrite.summation'};
        
        if (defined($self->{crit}) && $self->{crit} ne "" && ($total_read_counter >= $self->{crit})) {
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                "'$total_read_counter' read iops on '" . $_ . "'" . $self->vm_iops_details('disk.numberRead.summation', $datastore_lun{$_}, \%ref_ids_vm));
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif (defined($self->{warn}) && $self->{warn} ne "" && ($total_read_counter >= $self->{warn})) {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                "'$total_read_counter' read on '" . $_ . "'" . $self->vm_iops_details('disk.numberRead.summation', $datastore_lun{$_}, \%ref_ids_vm));
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        }
        if (defined($self->{crit}) && $self->{crit} ne "" && ($total_write_counter >= $self->{crit})) {
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                "'$total_write_counter' write iops on '" . $_ . "'" . $self->vm_iops_details('disk.numberWrite.summation', $datastore_lun{$_}, \%ref_ids_vm));
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif (defined($self->{warn}) && $self->{warn} ne "" && ($total_write_counter >= $self->{warn})) {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                "'$total_write_counter' write iops on '" . $_ . "'" . $self->vm_iops_details('disk.numberWrite.summation', $datastore_lun{$_}, \%ref_ids_vm));
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        }
        
        if ($self->{filter} == 1) {
            $perfdata .= " 'riops_" . $_ . "'=" . $total_read_counter . "iops;$self->{warn};$self->{crit};0; 'wiops_" . $_ . "'=" . $total_write_counter . "iops;$self->{warn};$self->{crit};0;";
        } else {
            $perfdata .= " 'riops=" . $total_read_counter . "iops;$self->{warn};$self->{crit};0; wiops=" . $total_write_counter . "iops;$self->{warn};$self->{crit};0;";
        }
    }

    if ($output_unknown ne "") {
        $output .= $output_append . "UNKNOWN - $output_unknown";
        $output_append = ". ";
    }
    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - $output_critical";
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - $output_warning";
    }
    if ($status == 0) {
        $output = "All Datastore IOPS counters are ok";
    }
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output|$perfdata\n");
}

sub vm_iops_details {
    my ($self, $label, $ds_details, $ref_ids_vm) = @_;
    my $details = '';
    
    foreach my $value (keys %$ds_details) {
        # Dont need to display vm with iops < 1
        if ($value =~ /^vm.*?$label$/ && $ds_details->{$value} >= $self->{details_value}) {
            my ($vm_ids) = split(/_/, $value);
            $details .= " ['" . $ref_ids_vm->{$vm_ids} . "' " . $ds_details->{$value} . ']';
        }
    }
    
    return $details;
}

1;
