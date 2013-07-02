
package centreon::esxd::cmdlistnichost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'listnichost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($host) = @_;

    if (!defined($host) || $host eq "") {
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
    my @properties = ('config.network.pnic');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output_up = 'Nic Up List: ';
    my $output_down = 'Nic Down List: ';
    my $output_up_append = "";
    my $output_down_append = "";
    foreach (@{$$result[0]->{'config.network.pnic'}}) {
        if (defined($_->linkSpeed)) {
            $output_up .= $output_up_append . "'" . $_->device . "'";
            $output_up_append = ', ';
        } else {
            $output_down .= $output_down_append . "'" . $_->device . "'";
            $output_down_append = ', ';
        }
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output_up. $output_down.\n");
}

1;
