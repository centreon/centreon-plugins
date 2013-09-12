
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
    my ($vm, $filter, $warn, $crit) = @_;

    if (!defined($vm) || $vm eq "") {
        $self->{logger}->writeLogError("ARGS error: need vm hostname");
        return 1;
    }
    if (defined($warn) && $warn ne "" && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be a positive number");
        return 1;
    }
    if (defined($crit) && $crit ne "" && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: crit threshold must be a positive number");
        return 1;
    }
    if (defined($warn) && defined($crit) && $warn ne "" && $crit ne "" && $warn > $crit) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be lower than crit threshold");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lvm} = $_[0];
    $self->{filter} = (defined($_[1]) && $_[1] == 1) ? 1 : 0;
    $self->{warning} = ((defined($_[2]) and $_[2] ne '') ? $_[2] : 86400 * 3);
    $self->{critical} = ((defined($_[3]) and $_[3] ne '') ? $_[3] : 86400 * 5);
}

sub run {
    my $self = shift;

    if ($self->{obj_esxd}->{module_date_parse_loaded} == 0) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Need to install Date::Parse CPAN Module.\n");
        return ;
    }

    my %filters = ();

    if ($self->{filter} == 0) {
        $filters{name} =  qr/^\Q$self->{lvm}\E$/;
    } else {
        $filters{name} = qr/$self->{lvm}/;
    }
    my @properties = ('snapshot.rootSnapshotList', 'name');
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
    my $output_ok_unit = 'Snapshot(s) OK';
    
    foreach my $virtual (@$result) {
        if (!defined($virtual->{'snapshot.rootSnapshotList'})) {
            next;
        }
    
        foreach my $snapshot (@{$virtual->{'snapshot.rootSnapshotList'}}) {
            # 2012-09-21T14:16:17.540469Z
            my $create_time = Date::Parse::str2time($snapshot->createTime);
            if (!defined($create_time)) {
                $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
                centreon::esxd::common::output_add(\$output_unknown, \$output_unknown_append, ", ",
                        "Can't Parse date '" . $snapshot->createTime . "' for vm '" . $virtual->{'name'} . "'");
                next;
            }
            if (time() - $create_time >= $self->{critical}) {
                centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                    "[" . $virtual->{'name'}. "]");
                $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                last;
            } elsif (time() - $create_time >= $self->{warning}) {
                centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                    "[" . $virtual->{'name'}. "]");
                $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                last;
            }
        }
    }
    
    if ($output_unknown ne "") {
        $output .= $output_append . "UNKNOWN - $output_unknown";
        $output_append = ". ";
    }
    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - Snapshots for VM older than " . ($self->{critical} / 86400) . " days: $output_critical";
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - Snapshots for VM older than " . ($self->{warning} / 86400) . " days: $output_warning";
    }
    if ($status == 0) {
        if ($self->{filter} == 1) {
            $output .= $output_append . "All snapshots are ok";
        } else {
            $output .= $output_append . $output_ok_unit;
        }
    }

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
