
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
    $self->{filter} = (defined($_[1]) && $_[1] == 1) ? 1 : 0;
    $self->{on} = ((defined($_[2]) and $_[2] ne '') ? $_[2] : 0);
    $self->{warn} = ((defined($_[3]) and $_[3] ne '') ? $_[3] : 0);
    $self->{crit} = ((defined($_[4]) and $_[4] ne '') ? $_[4] : 0);
    $self->{skip_errors} = (defined($_[5]) && $_[5] == 1) ? 1 : 0;
}

sub run {
    my $self = shift;
    my %filters = ();

    if ($self->{filter} == 0) {
        $filters{name} =  qr/^\Q$self->{lvm}\E$/;
    } else {
        $filters{name} = qr/$self->{lvm}/;
    }
    my @properties = ('name', 'config.hardware.device', 'runtime.connectionState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    my $status = 0; # OK
    my $output = '';
    my $output_append = '';
    my $output_unknown = '';
    my $output_unknown_append = '';

    foreach my $virtual (@$result) {
        if (!centreon::esxd::common::is_connected($virtual->{'runtime.connectionState'}->val)) {
            if ($self->{skip_errors} == 0 || $self->{filter} == 0) {
                $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
                centreon::esxd::common::output_add(\$output_unknown, \$output_unknown_append, ", ",
                                                    "'" . $virtual->{name} . "' not connected");
            }
            next;
        }
    
        my $output_disk = '';
        foreach (@{$virtual->{'config.hardware.device'}}) {         
            if ($_->isa('VirtualDisk')) {
                if ($self->{on} == 1 && $self->{warn} == 1 && $_->backing->thinProvisioned == 1) {
                    $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                    $output_disk .= ' [' . $_->backing->fileName . ']';
                }
                if ($self->{on} == 1 && $self->{crit} == 1 && $_->backing->thinProvisioned == 1) {
                    $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                    $output_disk .= ' [' . $_->backing->fileName . ']';
                }
                if ($self->{on} == 0 && $self->{warn} == 1 && $_->backing->thinProvisioned != 1) {
                    $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                    $output_disk .= ' [' . $_->backing->fileName . ']';
                }
                if ($self->{on} == 0 && $self->{crit} == 1 && $_->backing->thinProvisioned != 1) {
                    $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                    $output_disk .= ' [' . $_->backing->fileName . ']';
                }
            }
        }
        
        if ($output_disk ne '') {
            centreon::esxd::common::output_add(\$output, \$output_append, ", ",
                                               'VM ' . $virtual->{name} . ':' . $output_disk);
        }
    }

    if ($output ne "" && $self->{on} == 1) {
        $output = "VirtualDisks thinprovisioning actived - $output.";
    } elsif ($output ne "" && $self->{on} == 0) {
        $output = "VirtualDisks thinprovisioning not actived - $output.";
    }
    if ($status == 0) {
        $output .= $output_append . "Thinprovisoning virtualdisks are ok.";
    }
    
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
