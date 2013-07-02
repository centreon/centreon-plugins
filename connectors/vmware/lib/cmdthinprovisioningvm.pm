
package centreon::esxd::cmdthinprovisioningvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'thinprovisioningvm';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($vm, $warn, $crit) = @_;

    if (!defined($vm) || $vm eq "") {
        $self->{logger}->writeLogError("ARGS error: need vm name");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lvm} = $_[0];
    $self->{on} = ((defined($_[1]) and $_[1] ne '') ? $_[1] : 0);
    $self->{warn} = ((defined($_[2]) and $_[2] ne '') ? $_[2] : 0);
    $self->{crit} = ((defined($_[3]) and $_[3] ne '') ? $_[3] : 0);
}

sub run {
    my $self = shift;

    my %filters = ('name' => $self->{lvm});
    my @properties = ('config.hardware.device', 'runtime.connectionState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::vm_state($self->{obj_esxd}, $self->{lvm}, 
                                                $$result[0]->{'runtime.connectionState'}->val,
                                                undef, 1) == 0);
    
    my $status = 0;
    my $output = ""; 
    my $output_append = '';
    foreach (@{$$result[0]->{'config.hardware.device'}}) {
        if ($_->isa('VirtualDisk')) {
            if ($self->{on} == 1 && $self->{warn} == 1 && $_->backing->thinProvisioned == 1) {
                $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                centreon::esxd::common::output_add(\$output, \$output_append, ", ",
                                                   "'" . $_->backing->fileName . "'");
            }
            if ($self->{on} == 1 && $self->{crit} == 1 && $_->backing->thinProvisioned == 1) {
                $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                centreon::esxd::common::output_add(\$output, \$output_append, ", ",
                                                   "'" . $_->backing->fileName . "'");
            }
            if ($self->{on} == 0 && $self->{warn} == 1 && $_->backing->thinProvisioned != 1) {
                $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                centreon::esxd::common::output_add(\$output, \$output_append, ", ",
                                                   "'" . $_->backing->fileName . "'");
            }
            if ($self->{on} == 0 && $self->{crit} == 1 && $_->backing->thinProvisioned != 1) {
                $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                centreon::esxd::common::output_add(\$output, \$output_append, ", ",
                                                   "'" . $_->backing->fileName . "'");
            }
        }
    }
    
    if ($output ne "" && $self->{on} == 1) {
        $output = "VirtualDisks $output: thinprovisioning actived.";
    } elsif ($output ne "" && $self->{on} == 0) {
        $output = "VirtualDisks $output: thinprovisioning not actived.";
    } else {
        $output = "Thinprovisoning virtualdisks are ok.";
    }
    
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
