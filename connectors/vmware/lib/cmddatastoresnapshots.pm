
package centreon::esxd::cmddatastoresnapshots;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'datastore-snapshots';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($ds, $filter, $warn, $crit, $warn2, $crit2) = @_;

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
    if (defined($warn2) && $warn2 ne "" && $warn2 !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: warn2 threshold must be a positive number");
        return 1;
    }
    if (defined($crit2) && $crit2 ne "" && $crit2 !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: crit2 threshold must be a positive number");
        return 1;
    }
    if (defined($warn2) && defined($crit2) && $warn2 ne "" && $crit2 ne "" && $warn2 > $crit2) {
        $self->{logger}->writeLogError("ARGS error: warn2 threshold must be lower than crit2 threshold");
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
    $self->{warn2} = (defined($_[4]) ? $_[4] : '');
    $self->{crit2} = (defined($_[5]) ? $_[5] : '');
    $self->{skip_errors} = (defined($_[6]) && $_[6] == 1) ? 1 : 0;
}

sub run {
    my $self = shift;
    my %filters = ();

    if ($self->{filter} == 0) {
        $filters{name} =  qr/^\Q$self->{ds}\E$/;
    } else {
        $filters{name} = qr/$self->{ds}/;
    }

    my @properties = ('summary.accessible', 'summary.name', 'browser');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my @ds_array = ();
    my %ds_names = ();
    foreach my $entity_view (@$result) {
        next if (!centreon::esxd::common::is_accessible($entity_view->{'summary.accessible'}));
        if (defined($entity_view->browser)) {
            push @ds_array, $entity_view->browser;
            if ($self->{filter} == 1) {
                $ds_names{$entity_view->{mo_ref}->{value}} = $entity_view->{'summary.name'};
            }
        }
    }
    
    @properties = ();
    my $result2;
    return if (!($result2 = centreon::esxd::common::get_views($self->{obj_esxd}, \@ds_array, \@properties)));
   
    my $status = 0; # OK
    my $output = '';
    my $output_append = '';
    my $output_warning = ""; 
    my $output_warning_append = '';
    my $output_critical = ""; 
    my $output_critical_append = '';
    my $output_warning_total = ""; 
    my $output_warning_total_append = '';
    my $output_critical_total = ""; 
    my $output_critical_total_append = '';
    my $output_unknown = '';
    my $output_unknown_append = '';
    my $output_ok_unit = '';
    my $perfdata = '';

    foreach my $browse_ds (@$result2) {
        my $dsName; 
        if ($self->{filter} == 1) {
            my $tmp_name = $browse_ds->{mo_ref}->{value};
            $tmp_name =~ s/^datastoreBrowser-//i;
            $dsName = $ds_names{$tmp_name};
        } else {
            $dsName = $self->{ds};
        }

        my ($snapshots, $msg) = centreon::esxd::common::search_in_datastore($self->{obj_esxd}, $browse_ds, '[' . $dsName . ']', [VmSnapshotFileQuery->new()], 1);
        if (!defined($snapshots)) {
            $msg =~ s/\n/ /g;
            if ($msg =~ /NoPermissionFault/i) {
                $msg = "Not enough permissions";
            }
            if ($self->{skip_errors} == 0 || $self->{filter} == 0) {
                $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
                centreon::esxd::common::output_add(\$output_unknown, \$output_unknown_append, ", ",
                                                   "'" . $dsName . "' $msg");
            }
            next;
        }

        my $total_size = 0;
        my $lwarn = '';
        my $lcrit = '';
        foreach (@$snapshots) {
            if (defined($_->file)) {
                foreach my $x (@{$_->file}) {
                    if (defined($self->{crit2}) && $self->{crit2} ne '' && $x->fileSize >= $self->{crit2}) {
                        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                        $lwarn .= " [" . $_->folderPath . ']=>[' . $x->path . "]";
                    } elsif (defined($self->{warn2}) && $self->{warn2} ne '' && $x->fileSize >= $self->{warn2}) {
                        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                        $lcrit .= " [" . $_->folderPath . ']=>[' . $x->path . "]";
                    }
                    $total_size += $x->fileSize;
                }
            }
        }
        
        if ($lcrit ne '') {
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                                               "'$dsName'" . $lcrit);
        }
        if ($lwarn ne '') {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                                                "'$dsName'" . $lwarn);
        }
        
        if (defined($self->{crit}) && $self->{crit} && $total_size >= $self->{crit}) {
           centreon::esxd::common::output_add(\$output_critical_total, \$output_critical_total_append, ", ",
                        "'$dsName' Total snapshots used " . centreon::esxd::common::simplify_number($total_size / 1024 / 1024) . "MB");
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif (defined($self->{warn}) && $self->{warn} && $total_size >= $self->{warn}) {
            centreon::esxd::common::output_add(\$output_warning_total, \$output_warning_total_append, ", ",
                        "'$dsName' Total snapshots used " . centreon::esxd::common::simplify_number($total_size / 1024 / 1024) . "MB");
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        } else {
            $output_ok_unit .= "'$dsName' Total snapshots size is ok.";
        }
        
        if ($self->{filter} == 1) {
            $perfdata .= " 'total_size_" . $dsName . "'=" . $total_size . "o;$self->{warn};$self->{crit};0;";
        } else {
            $perfdata .= " 'total_size=" . $total_size . "o;$self->{warn};$self->{crit};0;";
        }
    }

    if ($output_unknown ne "") {
        $output .= $output_append . "UNKNOWN - $output_unknown";
        $output_append = ". ";
    }
    if ($output_critical_total ne '' || $output_critical ne '') {
        $output .= $output_append . "CRITICAL -";
        if ($output_critical_total ne '') {
            $output .= " " . $output_critical_total;
            $output_append = ' -';
        }
        if ($output_critical ne '') {
            $output .= $output_append . " Snapshots size exceed limit: " . $output_critical;
        }
        $output_append = '. ';
    }
    if ($output_warning_total ne '' || $output_warning ne '') {
        $output .= $output_append . "WARNING -";
        if ($output_warning_total ne '') {
            $output .= " " . $output_warning_total;
            $output_append = ' -';
        }
        if ($output_warning ne '') {
            $output .= $output_append . " Snapshots size exceed limit: " . $output_warning;
        }
    }
    if ($status == 0) {
        if ($self->{filter} == 1) {
            $output .= $output_append . "All Total snapshots size is ok";
        } else {
            $output .= $output_append . $output_ok_unit;
        }
    }
    
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output|$perfdata\n");
}

1;
