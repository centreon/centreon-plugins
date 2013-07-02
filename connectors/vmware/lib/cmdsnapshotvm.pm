
package centreon::esxd::cmdsnapshotvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'snapshotvm';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($vm, $older) = @_;

    if (!defined($vm) || $vm eq "") {
        $self->{logger}->writeLogError("ARGS error: need vm hostname");
        return 1;
    }
    if (defined($older) && $older ne '' && $older !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: older arg must be a positive number");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lvm} = $_[0];
    $self->{older} = ((defined($_[1]) and $_[1] ne '') ? $_[1] : -1);
    $self->{warn} = ((defined($_[2]) and $_[2] ne '') ? $_[2] : 0);
    $self->{crit} = ((defined($_[3]) and $_[3] ne '') ? $_[3] : 0);
}

sub run {
    my $self = shift;

    if ($self->{older} != -1 && $self->{obj_esxd}->{module_date_parse_loaded} == 0) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Need to install Date::Parse CPAN Module.\n");
        return ;
    }

    my %filters = ('name' => $self->{lvm});
    my @properties = ('snapshot.rootSnapshotList');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my $status = 0; # OK
    my $output = 'Snapshot(s) OK';

    if (!defined($$result[0]->{'snapshot.rootSnapshotList'})) {
        $output = 'No current snapshot.';
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
        return ;
    }
    
    foreach my $snapshot (@{$$result[0]->{'snapshot.rootSnapshotList'}}) {
        if ($self->{older} != -1) {
            # 2012-09-21T14:16:17.540469Z
            my $create_time = Date::Parse::str2time($snapshot->createTime);
            if (!defined($create_time)) {
                $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
                $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't Parse date '" . $snapshot->createTime . "'.\n");
                return ;
            }
            if (time() - $create_time > $self->{older}) {
                if ($self->{warn} == 1) {
                    $output = 'Older snapshot problem (' . $snapshot->createTime . ').';
                    $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                }
                if ($self->{crit} == 1) {
                    $output = 'Older snapshot problem (' . $snapshot->createTime . ').';
                    $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                }
            }
        } elsif ($self->{older} == -1) {
            if ($self->{warn} == 1) {
                $output = 'There is at least one snapshot.';
                $status = centreon::esxd::common::errors_mask($status, 'WARNING');
            }
            if ($self->{crit} == 1) {
                $output = 'There is at least one snapshot.';
                $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
            }
        }
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
