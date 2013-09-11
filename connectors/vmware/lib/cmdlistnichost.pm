
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
    my %nic_in_vswitch = ();

    my %filters = ('name' => $self->{lhost});
    my @properties = ('config.network.pnic', 'config.network.vswitch');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    # Get Name from vswitch
    foreach (@{$$result[0]->{'config.network.vswitch'}}) {
        foreach my $keynic (@{$_->pnic}) {
            $nic_in_vswitch{$keynic} = 1;
        }
    }

    my $status = 0; # OK
    my $output_up = 'Nic Up List: ';
    my $output_down = 'Nic Down List: ';
    my $output_down_no_vswitch = 'Nic Down List (not in vswitch): ';
    my $output_up_append = "";
    my $output_down_append = "";
    my $output_down_no_vswitch_append = "";
    foreach (@{$$result[0]->{'config.network.pnic'}}) {
        if (defined($_->linkSpeed)) {
            $output_up .= $output_up_append . "'" . $_->device . "'";
            $output_up_append = ', ';
        } else {
            if (defined($nic_in_vswitch{$_->key})) {
                $output_down .= $output_down_append . "'" . $_->device . "'";
                $output_down_append = ', ';
            } else {
                $output_down_no_vswitch .= $output_down_no_vswitch_append . "'" . $_->device . "'";
                $output_down_no_vswitch_append = ', ';
            }
        }
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output_up. $output_down. $output_down_no_vswitch.\n");
}

1;
