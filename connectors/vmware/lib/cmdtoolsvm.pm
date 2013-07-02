
package centreon::esxd::cmdtoolsvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'toolsvm';
    
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
}

sub run {
    my $self = shift;

    my %filters = ('name' => $self->{lvm});
    my @properties = ('summary.guest.toolsStatus', 'runtime.connectionState', 'runtime.powerState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::vm_state($self->{obj_esxd}, $self->{lvm}, 
                                                $$result[0]->{'runtime.connectionState'}->val,
                                                $$result[0]->{'runtime.powerState'}->val) == 0);

    
    my $status = 0; # OK
    my $output = '';

    my $tools_status = lc($$result[0]->{'summary.guest.toolsStatus'}->val);
    if ($tools_status eq 'toolsnotinstalled') {
        $output = "VMTools not installed on VM '" . $self->{lvm} . "'.";
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    } elsif ($tools_status eq 'toolsnotrunning') {
        $output = "VMTools not running on VM '" . $self->{lvm} . "'.";
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    } elsif ($tools_status eq 'toolsold') {
        $output = "VMTools not up-to-date on VM '" . $self->{lvm} . "'.";
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    } else {
        $output = "VMTools are OK on VM '" . $self->{lvm} . "'.";
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
