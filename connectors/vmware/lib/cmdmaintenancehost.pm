
package centreon::esxd::cmdmaintenancehost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'maintenancehost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($lhost) = @_;

    if (!defined($lhost) || $lhost eq "") {
        $self->{logger}->writeLogError("ARGS error: need hostname");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lhost} = $_[0];
}

sub run {
    my $self = shift;

    my %filters = ('name' => $self->{lhost});
    my @properties = ('runtime.inMaintenanceMode');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output = '';

    foreach my $entity_view (@$result) {
        if ($entity_view->{'runtime.inMaintenanceMode'} ne "false") {
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
            $output = "Server " . $self->{lhost} . " is on maintenance mode.";
        } else {
            $output = "Server " . $self->{lhost} . " is not on maintenance mode.";
        }
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
