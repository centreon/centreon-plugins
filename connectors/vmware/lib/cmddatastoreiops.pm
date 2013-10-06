
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
    my ($ds, $warn, $crit) = @_;

    if (!defined($ds) || $ds eq "") {
        $self->{logger}->writeLogError("ARGS error: need datastore name");
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
    $self->{skip_errors} = (defined($_[4]) && $_[4] == 1) ? 1 : 0;
}

sub run {
    my $self = shift;

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
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

    use Data::Dumper;
    
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

    @properties = ('name', 'runtime.connectionState');
    my $result2 = centreon::esxd::common::get_views($self->{obj_esxd}, \@vm_array, \@properties);
    if (!defined($result2)) {
        return ;
    }
    
    my %ref_ids_vm = ();
    foreach (@$result2) {
        $ref_ids_vm{$_->{mo_ref}->{value}} = $_->{name};
    }
    
    print STDERR Data::Dumper::Dumper(%ref_ids_vm);

    # Vsphere >= 4.1
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $result2, 
                        [{'label' => 'disk.numberRead.summation', 'instances' => ['*']},
                        {'label' => 'disk.numberWrite.summation', 'instances' => ['*']}],
                        $self->{obj_esxd}->{perfcounter_speriod}, 1, 1);
    print STDERR Data::Dumper::Dumper($values); 
    return ;                    
    
    return if (centreon::esxd::common::performance_errors($self->{obj_esxd}, $values) == 1);

    
    
    foreach (keys %$values) {
        my ($id, $disk_name) = split(/:/);
        $datastore_lun{$disk_name{$disk_name}}{$self->{obj_esxd}->{perfcounter_cache_reverse}->{$id}} += $values->{$_}[0];
    }

    my $status = 0; # OK
    my $output = '';
    my $output_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output_critical = '';
    my $output_critical_append = '';
    my $perfdata = '';
    foreach (keys %datastore_lun) {
        my $read_counter = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($datastore_lun{$_}{'disk.numberRead.summation'} / $self->{obj_esxd}->{perfcounter_speriod}));
        my $write_counter = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($datastore_lun{$_}{'disk.numberWrite.summation'} / $self->{obj_esxd}->{perfcounter_speriod}));

        if (defined($self->{crit}) && $self->{crit} ne "" && ($read_counter >= $self->{crit})) {
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                "read on '" . $_ . "' is $read_counter ms");
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif (defined($self->{warn}) && $self->{warn} ne "" && ($read_counter >= $self->{warn})) {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                "read on '" . $_ . "' is $read_counter ms");
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        }
        if (defined($self->{crit}) && $self->{crit} ne "" && ($write_counter >= $self->{crit})) {
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                "write on '" . $_ . "' is $write_counter ms");
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif (defined($self->{warn}) && $self->{warn} ne "" && ($write_counter >= $self->{warn})) {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                "write on '" . $_ . "' is $write_counter ms");
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        }
            
        $perfdata .= " 'riops_" . $_ . "'=" . $read_counter . "iops 'wiops_" . $_ . "'=" . $write_counter . 'iops';
    }

    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - Datastore IOPS counter: $output_critical";
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - Datastore IOPS counter: $output_warning";
    }
    if ($status == 0) {
        $output = "All Datastore IOPS counters are ok";
    }
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output|$perfdata\n");
}

1;
