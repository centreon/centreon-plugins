
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
    my ($ds, $warn, $crit, $warn2, $crit2) = @_;

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
    $self->{warn} = (defined($_[1]) ? $_[1] : '');
    $self->{crit} = (defined($_[2]) ? $_[2] : '');
    $self->{warn2} = (defined($_[3]) ? $_[3] : '');
    $self->{crit2} = (defined($_[4]) ? $_[4] : '');
}

sub run {
    my $self = shift;

    my %filters = ('summary.name' => $self->{ds});
    my @properties = ('summary.accessible', 'browser');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::datastore_state($self->{obj_esxd}, $self->{ds}, $$result[0]->{'summary.accessible'}) == 0);

    @properties = ();
    my $browse_ds;
    return if (!($browse_ds = centreon::esxd::common::get_view($self->{obj_esxd}, $$result[0]->{'browser'}, \@properties)));
   
    my $snapshots;
    return if (!($snapshots = centreon::esxd::common::search_in_datastore($self->{obj_esxd}, $browse_ds, '[' . $self->{ds} . ']', [VmSnapshotFileQuery->new()])));
   
    my $status = 0; # OK
    my $output = '';
    my $output_append = '';
    my $output_warning = ""; 
    my $output_warning_append = '';
    my $output_critical = ""; 
    my $output_critical_append = '';
    my $total_size = 0;

    foreach (@$snapshots) {
        if (defined($_->file)) {
            foreach my $x (@{$_->file}) {
                if (defined($self->{crit2}) && $self->{crit2} ne '' && $x->fileSize >= $self->{crit2}) {
                    $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                    centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                                                   "'" . $_->folderPath . ' => ' . $x->path . "'");
                } elsif (defined($self->{warn2}) && $self->{warn2} ne '' && $x->fileSize >= $self->{warn2}) {
                    $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                    centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                                                   "'" . $_->folderPath . ' => ' . $x->path . "'");
                }
                $total_size += $x->fileSize;
            }
        }
    }

    if ($output_critical ne '') {
        $output .= "CRITICAL - Snapshot size exceed limit: $output_critical.";
        $output_append = " ";
    }
    if ($output_warning ne '') {
        $output .= $output_append . "WARNING - Snapshot size exceed limit: $output_warning.";
        $output_append = " ";
    }
    
    if (defined($self->{crit}) && $self->{crit} && $total_size >= $self->{crit}) {
        $output .= $output_append . "CRITICAL - Total snapshots size exceed limit: " . centreon::esxd::common::simplify_number($total_size / 1024 / 1024) . "MB.";
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    } elsif (defined($self->{warn}) && $self->{warn} && $total_size >= $self->{warn}) {
        $output .= $output_append . "WARNING - Total snapshots size exceed limit: " . centreon::esxd::common::simplify_number($total_size / 1024 / 1024) . "MB.";
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    } else {
        $output .= $output_append . "OK - Total snapshots size is ok.";
    }
    $output .= "|total_size=" . $total_size . "o;$self->{warn};$self->{crit};0;";
    
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
