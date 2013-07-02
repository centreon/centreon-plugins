
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
    my ($ds, $warn, $crit) = @_;

    if (!defined($ds) || $ds eq "") {
        $self->{logger}->writeLogError("ARGS error: need datastore name");
        return 1;
    }
    if (defined($warn) && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be a positive number");
        return 1;
    } 
    if (defined($crit) && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: crit threshold must be a positive number");
        return 1;
    }
    if (defined($warn) && defined($crit) && $warn > $crit) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be lower than crit threshold");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{ds} = $_[0];
    $self->{warn} = (defined($_[1]) ? $_[1] : 80);
    $self->{crit} = (defined($_[2]) ? $_[2] : 90);
}

sub run {
    my $self = shift;

    my %filters = ('name' => $self->{ds});
    my @properties = ('summary');

    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output = "";
    if ($$result[0]->summary->accessible == 1) {
        my $dsName = $$result[0]->summary->name;
        my $capacity = $$result[0]->summary->capacity;
        my $free = $$result[0]->summary->freeSpace;
        my $pct = ($capacity - $free) / $capacity * 100;

        my $usedD = ($capacity - $free) / 1024 / 1024 / 1024;
        my $sizeD = $capacity / 1024 / 1024 / 1024;
    
        $output = "Datastore $dsName - used ".sprintf("%.2f", $usedD)." Go / ".sprintf("%.2f", $sizeD)." Go (".sprintf("%.2f", $pct)." %) |used=".($capacity - $free)."o;;;0;".$capacity." size=".$capacity."o\n";
        if ($pct >= $self->{warn}) {
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        }
        if ($pct > $self->{crit}) {
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        }
    } else {
        $output = "Datastore '" . $self->{ds} . "' summary not accessible.";
        $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
    }
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
