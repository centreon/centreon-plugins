
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
    my ($lhost, $warn, $crit) = @_;

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
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lhost} = $_[0];
    $self->{warn} = (defined($_[1]) ? $_[1] : '');
    $self->{crit} = (defined($_[2]) ? $_[2] : '');
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

    foreach (@$result) {
        my $power_value = lc($_->{'runtime.powerState'}->val);
        if ($power_value eq 'poweredon') {
            $num_poweron++;
        }
    }
    if (defined($self->{crit}) && $self->{crit} ne "" && ($num_poweron >= $self->{crit})) {
        $output = "CRITICAL: $num_poweron VM running.";
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    } elsif (defined($self->{warn}) && $self->{warn} ne "" && ($num_poweron >= $self->{warn})) {
        $output = "WARNING: $num_poweron VM running.";
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    } else {
        $output = "OK: $num_poweron VM running.";
    }
    
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output|count=$num_poweron\n");
}

1;
