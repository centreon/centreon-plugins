
package centreon::esxd::cmddatastoresvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'datastoresvm';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($lvm, $warn, $crit) = @_;

    if (!defined($lvm) || $lvm eq "") {
        $self->{logger}->writeLogError("ARGS error: need vm name");
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
    $self->{lvm} = $_[0];
    $self->{warn} = (defined($_[1]) ? $_[1] : '');
    $self->{crit} = (defined($_[2]) ? $_[2] : '');
}

sub run {
    my $self = shift;

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ('name' => $self->{lvm});
    my @properties = ('datastore');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my @ds_array = ();
    foreach my $entity_view (@$result) {
        if (defined $entity_view->datastore) {
                @ds_array = (@ds_array, @{$entity_view->datastore});
        }
    }
    @properties = ('info');
    my $result2 = centreon::esxd::common::get_views($self->{obj_esxd}, \@ds_array, \@properties);
    if (!defined($result2)) {
        return ;
    }

    #my %uuid_list = ();
    my %disk_name = ();
    my %datastore_lun = ();
    foreach (@$result2) {
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

    # Vsphere >= 4.1
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $$result[0], 
                        [{'label' => 'disk.numberRead.summation', 'instances' => ['*']},
                        {'label' => 'disk.numberWrite.summation', 'instances' => ['*']}],
                        $self->{obj_esxd}->{perfcounter_speriod});

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
