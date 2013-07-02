
package centreon::esxd::cmduptimehost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'uptimehost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($lhost) = @_;

    if (!defined($lhost) || $lhost eq "") {
        $self->{logger}->writeLogError("ARGS error: need host name");
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

    if ($self->{obj_esxd}->{module_date_parse_loaded} == 0) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Need to install Date::Parse Perl Module.\n");
        return ;
    }
    
    my %filters = ('name' => $self->{lhost});
    my @properties = ('runtime.bootTime');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $create_time = Date::Parse::str2time($$result[0]->{'runtime.bootTime'});
    if (!defined($create_time)) {
        $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't Parse date '" . $$result[0]->{'runtime.bootTime'} . "'.\n");
        return ;
    }
    my $diff_time = time() - $create_time;
    my $days = int($diff_time / 60 / 60 / 24);

    my $output = '';
    my $status = 0; # OK

    $output = "Uptime (in day): $days|uptime=" . $days . "day(s)\n";

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
