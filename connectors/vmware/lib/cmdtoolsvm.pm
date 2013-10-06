
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
    $self->{filter} = (defined($_[1]) && $_[1] == 1) ? 1 : 0;
    $self->{skip_errors} = (defined($_[2]) && $_[2] == 1) ? 1 : 0;
}

sub run {
    my $self = shift;
    my %filters = ();

    if ($self->{filter} == 0) {
        $filters{name} =  qr/^\Q$self->{lvm}\E$/;
    } else {
        $filters{name} = qr/$self->{lvm}/;
    }
 
    my @properties = ('name', 'summary.guest.toolsStatus', 'runtime.connectionState', 'runtime.powerState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    my $status = 0; # OK
    my $output = '';
    my $output_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output_critical = '';
    my $output_critical_append = '';
    my $output_unknown = '';
    my $output_unknown_append = '';
    my $not_installed = '';
    my $not_running = '';
    my $not_up2date = '';

    foreach my $virtual (@$result) {
        if (!centreon::esxd::common::is_connected($virtual->{'runtime.connectionState'}->val)) {
            if ($self->{skip_errors} == 0 || $self->{filter} == 0) {
                $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
                centreon::esxd::common::output_add(\$output_unknown, \$output_unknown_append, ", ",
                                                    "'" . $virtual->{name} . "' not connected");
            }
            next;
        }
    
        my $tools_status = lc($virtual->{'summary.guest.toolsStatus'}->val);
        if ($tools_status eq 'toolsnotinstalled') {
            $not_installed .= ' [' . $virtual->{name} . ']';
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif ($tools_status eq 'toolsnotrunning') {
            $not_running .= ' [' . $virtual->{name} . ']';
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif ($tools_status eq 'toolsold') {
            $not_up2date .= ' [' . $virtual->{name} . ']';
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        }
    }
    
    if ($not_installed ne '') {
        centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                                           "VMTools not installed on VM:" . $not_installed);
    }
    if ($not_running ne '') {
        centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                                           "VMTools not running on VM:" . $not_running);
    }
    if ($not_running ne '') {
        centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                                           "VMTools not up-to-date on VM:" . $not_running);
    }
                                       
    if ($output_unknown ne "") {
        $output .= $output_append . "UNKNOWN - " . $output_unknown;
        $output_append = ". ";
    }
    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - " . $output_critical;
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - " . $output_warning;
    }
    if ($status == 0) {
        $output .= $output_append . "VMTools are OK.";
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
