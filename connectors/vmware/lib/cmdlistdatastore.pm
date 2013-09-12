
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
    $self->{xml} = (defined($_[0]) && $_[0] == 1) ? 1 : 0;
    $self->{show_attributes} = (defined($_[1]) && $_[1] == 1) ? 1 : 0;
}

sub run {
    my $self = shift;

    if ($self->{show_attributes} == 1) {
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status(0) . "|<data><element>name</element></data>\n");
        return ;
    }
    
    my %filters = ();
    my @properties = ('summary');

    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'Datastore', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output = 'Datastore List: ';
    my $output_append = "";
    my $xml_output = '<data>';
    foreach my $datastore (@$result) {
        if ($datastore->summary->accessible) {
            $output .= $output_append . "'" . $datastore->summary->name . "'";
            $output_append = ', ';
        }
        $xml_output .= '<element name="' . $datastore->summary->name . '" />';
    }
    $xml_output .= '</data>';

    if ($self->{xml} == 1) {
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$xml_output\n");
    } else {
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
    }
}

1;
