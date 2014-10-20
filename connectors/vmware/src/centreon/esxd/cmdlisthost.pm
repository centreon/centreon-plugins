
package centreon::esxd::cmdlisthost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'listhost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    return 0;
}

sub initArgs {
    my $self = shift;
}

sub run {
    my $self = shift;
    my %filters = ();
    my @properties = ('name');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output = 'Host List: ';
    my $output_append = "";

    foreach my $entity_view (@$result) {
        $output .= $output_append . $entity_view->{name};
        $output_append = ', ';
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
