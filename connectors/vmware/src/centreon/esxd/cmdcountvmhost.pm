
package centreon::esxd::cmdcountvmhost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'countvmhost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($lhost, $warn, $crit, $warn2, $crit2) = @_;

    if (!defined($lhost) || $lhost eq "") {
        $self->{logger}->writeLogError("ARGS error: need host name");
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
    $self->{lhost} = $_[0];
    $self->{warn} = (defined($_[1]) ? $_[1] : '');
    $self->{crit} = (defined($_[2]) ? $_[2] : '');
    $self->{warn2} = (defined($_[3]) ? $_[3] : '');
    $self->{crit2} = (defined($_[4]) ? $_[4] : '');
}

sub run {
    my $self = shift;

    my %filters = ('name' => $self->{lhost});
    my @properties = ('vm', 'runtime.connectionState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::host_state($self->{obj_esxd}, $self->{lhost}, 
                                                $$result[0]->{'runtime.connectionState'}->val) == 0);

    my @vm_array = ();
    foreach my $entity_view (@$result) {
        if (defined $entity_view->vm) {
            @vm_array = (@vm_array, @{$entity_view->vm});
        }
    }
    @properties = ('runtime.powerState');
    $result = centreon::esxd::common::get_views($self->{obj_esxd}, \@vm_array, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $output = '';
    my $status = 0; # OK
    my $num_poweron = 0;
    my $num_powerother = 0;

    foreach (@$result) {
        my $power_value = lc($_->{'runtime.powerState'}->val);
        if ($power_value eq 'poweredon') {
            $num_poweron++;
        } else {
            $num_powerother++;
        }
    }
    if (defined($self->{crit}) && $self->{crit} ne "" && ($num_poweron >= $self->{crit})) {
        $output = "CRITICAL: $num_poweron VM running";
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    } elsif (defined($self->{warn}) && $self->{warn} ne "" && ($num_poweron >= $self->{warn})) {
        $output = "WARNING: $num_poweron VM running";
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    } else {
        $output .= "OK: $num_poweron VM running";
    }
    
    if (defined($self->{crit2}) && $self->{crit2} ne "" && ($num_powerother >= $self->{crit2})) {
        $output .= " - CRITICAL: $num_powerother VM not running.";
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    } elsif (defined($self->{warn2}) && $self->{warn2} ne "" && ($num_powerother >= $self->{warn2})) {
        $output .= " - WARNING: $num_powerother VM not running.";
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    } else {
        $output .= " - OK: $num_powerother VM not running.";
    }
    
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output|count_on=$num_poweron;$self->{warn};$self->{crit};0; count_not_on=$num_powerother;$self->{warn2};$self->{crit2};0;\n");
}

1;
