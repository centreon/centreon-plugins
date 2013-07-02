
package centreon::esxd::cmdlistdatastore;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'listdatastore';
    
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
    my @properties = ('summary');

    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output = 'Datastore List: ';
    my $output_append = "";
    foreach my $datastore (@$result) {
        if ($datastore->summary->accessible) {
            $output .= $output_append . "'" . $datastore->summary->name . "'";
            $output_append = ', ';
        }
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
