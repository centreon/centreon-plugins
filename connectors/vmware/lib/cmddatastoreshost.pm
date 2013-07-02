
package centreon::esxd::cmddatastoreshost;

use strict;
use warnings;
use File::Basename;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'datastoreshost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($lhost, $warn, $crit) = @_;

    if (!defined($lhost) || $lhost eq "") {
        $self->{logger}->writeLogError("ARGS error: need host name");
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
    $self->{lhost} = $_[0];
    $self->{warn} = (defined($_[1]) ? $_[1] : '');
    $self->{crit} = (defined($_[2]) ? $_[2] : '');
    $self->{filter_ds} = (defined($_[3]) ? $_[3] : '');
}

sub run {
    my $self = shift;

    my %valid_ds = ();
    my $filter_ok = 0;
    if ($self->{filter_ds} ne '') {
        foreach (split /,/, $self->{filter_ds}) {
            $valid_ds{$_} = 1;
        }
    }
    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ('name' => $self->{lhost});
    my @properties = ('config.fileSystemVolume.mountInfo');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    my %uuid_list = ();
    my %disk_name = ();
    foreach (@{$$result[0]->{'config.fileSystemVolume.mountInfo'}}) {
        if ($_->volume->isa('HostVmfsVolume')) {
            $uuid_list{$_->volume->uuid} = $_->volume->name;
            # Not need. We are on Datastore level (not LUN level)
            #foreach my $extent (@{$_->volume->extent}) {
            #    $disk_name{$extent->diskName} = $_->volume->name;
            #}
        }
        if ($_->volume->isa('HostNasVolume')) {
            $uuid_list{basename($_->mountInfo->path)} = $_->volume->name;
        }
    }

    # Vsphere >= 4.1
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $$result[0], 
                        [{'label' => 'datastore.totalReadLatency.average', 'instances' => ['*']},
                        {'label' => 'datastore.totalWriteLatency.average', 'instances' => ['*']}],
                        $self->{obj_esxd}->{perfcounter_speriod});

    my $status = 0; # OK
    my $output = '';
    my $output_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output_critical = '';
    my $output_critical_append = '';
    my $perfdata = '';
    foreach (keys %uuid_list) {
        if ($self->{filter_ds} ne '' and !defined($valid_ds{$uuid_list{$_}})) {
            next;
        }
        if (defined($values->{$self->{obj_esxd}->{perfcounter_cache}->{'datastore.totalReadLatency.average'}->{'key'} . ":" . $_}) and
            defined($values->{$self->{obj_esxd}->{perfcounter_cache}->{'datastore.totalWriteLatency.average'}->{'key'} . ":" . $_})) {
            my $read_counter = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'datastore.totalReadLatency.average'}->{'key'} . ":" . $_}[0]));
            my $write_counter = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'datastore.totalWriteLatency.average'}->{'key'} . ":" . $_}[0]));
            if (defined($self->{crit}) && $self->{crit} ne "" && ($read_counter >= $self->{crit})) {
                centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                    "read on '" . $uuid_list{$_} . "' is $read_counter ms");
                $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
            } elsif (defined($self->{warn}) && $self->{warn} ne "" && ($read_counter >= $self->{warn})) {
                centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                    "read on '" . $uuid_list{$_} . "' is $read_counter ms");
                $status = centreon::esxd::common::errors_mask($status, 'WARNING');
            }
            if (defined($self->{crit}) && $self->{crit} ne "" && ($write_counter >= $self->{crit})) {
                centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                    "write on '" . $uuid_list{$_} . "' is $write_counter ms");
                $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
            } elsif (defined($self->{warn}) && $self->{warn} ne "" && ($write_counter >= $self->{warn})) {
                centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                    "write on '" . $uuid_list{$_} . "' is $write_counter ms");
                $status = centreon::esxd::common::errors_mask($status, 'WARNING');
            }
            
            $filter_ok = 1;
            $perfdata .= " 'trl_" . $uuid_list{$_} . "'=" . $read_counter . "ms 'twl_" . $uuid_list{$_} . "'=" . $write_counter . 'ms';
        }
    }

    if ($self->{filter_ds} ne '' and $filter_ok == 0) {
        $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status). "|Datastore names in filter are unknown.\n");
        return ;
    }
    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - Latency counter: $output_critical";
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - Latency counter: $output_warning";
    }
    if ($status == 0) {
        $output = "All Datastore latency counters are ok";
    }
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output|$perfdata\n");
}

1;
