
package centreon::esxd::cmddatastoreusage;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'datastore-usage';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($ds, $filter, $warn, $crit, $free, $units) = @_;

    if (!defined($ds) || $ds eq "") {
        $self->{logger}->writeLogError("ARGS error: need datastore name.");
        return 1;
    }
    if (defined($warn) && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be a positive number.");
        return 1;
    } 
    if (defined($crit) && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: crit threshold must be a positive number.");
        return 1;
    }
    if (defined($warn) && defined($crit) && (!defined($free) || $free != 1) && $warn > $crit) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be lower than crit threshold.");
        return 1;
    }
    if (defined($warn) && defined($crit) && defined($free) && $free == 1 && $warn < $crit) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be higher than crit threshold.");
        return 1;
    }
    if (defined($units) && ($units !~ /^(%|MB)/)) {
        $self->{logger}->writeLogError("ARGS error: units should be '%' or 'MB'.");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{ds} = $_[0];
    $self->{filter} = (defined($_[1]) && $_[1] == 1) ? 1 : 0;
    $self->{free} = (defined($_[4]) && $_[4] == 1) ? 1 : 0;
    $self->{warn} = (defined($_[2]) ? $_[2] : (($self->{free} == 1) ? 20 : 80));
    $self->{crit} = (defined($_[3]) ? $_[3] : (($self->{free} == 1) ? 10 : 90));
    $self->{units} = (defined($_[5])) ? $_[5] : '%';
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
    my @properties = ('summary');

    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    my $status = 0; # OK
    my $output = "";
    my $output_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output_critical = '';
    my $output_critical_append = '';
    my $output_unknown = '';
    my $output_unknown_append = '';
    my $output_ok_unit = '';
    my $perfdata = '';
    my ($warn_threshold, $crit_threshold);
    my ($pctwarn_threshold, $pctcrit_threshold) = ($self->{warn}, $self->{crit});
    
    if ($self->{units} eq '%' && $self->{free} == 1) {
        $pctwarn_threshold = 100 - $self->{warn};
        $pctcrit_threshold = 100 - $self->{crit};
    }
    
    foreach my $ds (@$result) {
        if (!centreon::esxd::common::is_accessible($ds->summary->accessible)) {
            if ($self->{skip_errors} == 0 || $self->{filter} == 0) {
                $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
                centreon::esxd::common::output_add(\$output_unknown, \$output_unknown_append, ", ",
                                                    "'" . $ds->summary->name . "' not accessible. Can be disconnected");
            }
            next;
        }
        
        # capacity 0...
        next if ($ds->summary->capacity <= 0);

        my $dsName = $ds->summary->name;
        my $capacity = $ds->summary->capacity;
        my $free = $ds->summary->freeSpace;
        
        if ($self->{units} eq 'MB' && $self->{free} == 1) {
            $warn_threshold = $capacity - ($self->{warn} * 1024 * 1024);
            $crit_threshold = $capacity - ($self->{crit} * 1024 * 1024);
        } elsif ($self->{units} eq 'MB' && $self->{free} == 0) {
            $warn_threshold = $self->{warn} * 1024 * 1024;
            $crit_threshold = $self->{crit} * 1024 * 1024;
        } else {
            $warn_threshold = ($capacity * $pctwarn_threshold) / 100;
            $crit_threshold = ($capacity * $pctcrit_threshold) / 100; 
        }
        
        my $pct = ($capacity - $free) / $capacity * 100;

        my $usedD = ($capacity - $free) / 1024 / 1024 / 1024;
        my $sizeD = $capacity / 1024 / 1024 / 1024;

        $output_ok_unit = "Datastore $dsName - used ".sprintf("%.2f", $usedD)." Go / ".sprintf("%.2f", $sizeD)." Go (".sprintf("%.2f", $pct)." %)";
        
        if ($self->{units} eq '%' && $pct >= $pctcrit_threshold) {
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                        "'$dsName' used ".sprintf("%.2f", $usedD)." Go / ".sprintf("%.2f", $sizeD)." Go (".sprintf("%.2f", $pct)." %)");
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif ($self->{units} eq '%' && $pct >= $pctwarn_threshold) {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                        "'$dsName' used ".sprintf("%.2f", $usedD)." Go / ".sprintf("%.2f", $sizeD)." Go (".sprintf("%.2f", $pct)." %)");
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        } elsif ($self->{units} eq 'MB' && ($capacity - $free) >= $crit_threshold) {
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                        "'$dsName' used ".sprintf("%.2f", $usedD)." Go / ".sprintf("%.2f", $sizeD)." Go (".sprintf("%.2f", $pct)." %)");
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif ($self->{units} eq 'MB' && ($capacity - $free) >= $warn_threshold) {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                        "'$dsName' used ".sprintf("%.2f", $usedD)." Go / ".sprintf("%.2f", $sizeD)." Go (".sprintf("%.2f", $pct)." %)");
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        }

        if ($self->{filter} == 1) {
            $perfdata .= " 'used_" . $dsName . "'=".($capacity - $free)."o;" . $warn_threshold . ";" . $crit_threshold . ";0;" . $capacity;
        } else {
            $perfdata .= " used=".($capacity - $free)."o;" . $warn_threshold . ";" . $crit_threshold . ";0;" . $capacity;
        }
    }
    
    if ($output_unknown ne "") {
        $output .= $output_append . "UNKNOWN - $output_unknown";
        $output_append = ". ";
    }
    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - Datastore(s): $output_critical";
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - Datastore(s): $output_warning";
    }
    if ($status == 0) {
        if ($self->{filter} == 1) {
            $output .= $output_append . "All Datastore usages are ok";
        } else {
            $output .= $output_append . $output_ok_unit;
        }
    }
    
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output|$perfdata\n");
}

1;
