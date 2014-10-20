
package centreon::esxd::cmdgetmap;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'getmap';
    
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
    $self->{lhost} = $_[0];
}

sub run {
    my $self = shift;

    my %filters = ();
    if (defined($self->{lhost}) and $self->{lhost} ne "") {
        %filters = ('name' => $self->{lhost});
    }
    my @properties = ('name', 'vm');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output = '';
    my $output_append = "";

    foreach my $entity_view (@$result) {
        $output .= $output_append . "ESX Host '" . $entity_view->name . "': ";
        my @vm_array = ();
        if (defined $entity_view->vm) {
                @vm_array = (@vm_array, @{$entity_view->vm});
        }

        @properties = ('name', 'summary.runtime.powerState');
        my $result2 = centreon::esxd::common::get_views($self->{obj_esxd}, \@vm_array, \@properties);
        if (!defined($result)) {
            return ;
        }
        
        my $output_append2 = '';
        foreach my $vm (@$result2) {
            if ($vm->{'summary.runtime.powerState'}->val eq "poweredOn") {
                $output .= $output_append2 . "[" . $vm->name . "]";
                $output_append2 = ', ';
            }
        }
        $output_append = ". ";
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
