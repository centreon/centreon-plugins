
package centreon::esxd::cmdlimitvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'limitvm';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($vm) = @_;

    if (!defined($vm) || $vm eq "") {
        $self->{logger}->writeLogError("ARGS error: need vm hostname");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lvm} = $_[0];
    $self->{filter} = (defined($_[1]) && $_[1] == 1) ? 1 : 0;
    $self->{warn} = (defined($_[2]) && $_[2] == 1) ? 1 : 0;
    $self->{crit} = (defined($_[3]) && $_[3] == 1) ? 1 : 0;
    if ($self->{warn} == 0 && $self->{crit} == 0) {
        $self->{warn} = 1;
    }
}

sub run {
    my $self = shift;

    my %filters = ();

    if ($self->{filter} == 0) {
        $filters{name} =  qr/^\Q$self->{lvm}\E$/;
    } else {
        $filters{name} = qr/$self->{lvm}/;
    }
    my @properties = ('name', 'config.hardware.device', 'config.cpuAllocation.limit', 'config.memoryAllocation.limit');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output = "";
    my $output_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output_critical = '';
    my $output_critical_append = '';
    my $output_unknown = '';
    my $output_unknown_append = '';
    
    foreach my $virtual (@$result) {
        my $limit_set_warn = '';
        my $limit_set_crit = '';

        # CPU Limit
        if ($self->{crit} == 1 && defined($virtual->{'config.cpuAllocation.limit'}) && $virtual->{'config.cpuAllocation.limit'} != -1) {
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
            $limit_set_crit = "/CPU"
        } elsif ($self->{warn} == 1 && defined($virtual->{'config.cpuAllocation.limit'}) && $virtual->{'config.cpuAllocation.limit'} != -1) {
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
            $limit_set_warn = "/CPU"
        }
        
        # Memory Limit
        if ($self->{crit} == 1 && defined($virtual->{'config.memoryAllocation.limit'}) && $virtual->{'config.memoryAllocation.limit'} != -1) {
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
            $limit_set_crit .= "/MEM"
        } elsif ($self->{warn} == 1 && defined($virtual->{'config.memoryAllocation.limit'}) && $virtual->{'config.memoryAllocation.limit'} != -1) {
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
            $limit_set_warn .= "/MEM"
        }
        
        # Disk
        foreach my $device (@{$virtual->{'config.hardware.device'}}) {
            if ($device->isa('VirtualDisk')) {
                if ($self->{crit} == 1 && defined($device->storageIOAllocation->limit) && $device->storageIOAllocation->limit != -1) {
                    $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                    $limit_set_crit .= "/DISK"
                } elsif ($self->{warn} == 1 && defined($device->storageIOAllocation->limit) && $device->storageIOAllocation->limit != -1) {
                    $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                    $limit_set_warn .= "/DISK"
                }
            }
        }
        
        # Set
        if ($limit_set_crit ne '') {
             centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                    "[" . $virtual->{'name'}. "]$limit_set_crit");
        } elsif ($limit_set_warn ne '') {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                    "[" . $virtual->{'name'}. "]$limit_set_warn");
        }
        
    }
    
    if ($output_unknown ne "") {
        $output .= $output_append . "UNKNOWN - $output_unknown";
        $output_append = ". ";
    }
    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - Limits for VMs: $output_critical";
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - Limits for VMs: $output_warning";
    }
    if ($status == 0) {
        $output .= $output_append . "Limits are ok";
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
