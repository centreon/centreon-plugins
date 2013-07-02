
package centreon::esxd::cmdstatushost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'statushost';
    
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
    my @properties = ('summary.overallStatus', 'runtime.connectionState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::host_state($self->{obj_esxd}, $self->{lhost}, 
                                                $$result[0]->{'runtime.connectionState'}->val) == 0);

    my $status = 0; # OK
    my $output = '';

    my %overallStatus = (
        'gray' => 'status is unknown',
         'green' => 'is OK',
        'red' => 'has a problem',
        'yellow' => 'might have a problem',
    );
    my %overallStatusReturn = (
        'gray' => 'UNKNOWN',
        'green' => 'OK',
        'red' => 'CRITICAL',
        'yellow' => 'WARNING'
    );

    foreach my $entity_view (@$result) {
        my $status_esx = $entity_view->{'summary.overallStatus'}->val;

        if (defined($status) && $overallStatus{$status_esx}) {
            $output = "The Server '" . $self->{lhost} . "' " . $overallStatus{$status_esx};
            $status = centreon::esxd::common::errors_mask($status, $overallStatusReturn{$status_esx});
        } else {
            $output = "Can't interpret data...";
            $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
        }
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
