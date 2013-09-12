
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
    $self->{ds} = (defined($_[3]) ? $_[3] : '');
    $self->{filter} = (defined($_[4]) && $_[4] == 1) ? 1 : 0;
}

sub run {
    my $self = shift;
    my $filter_ok = 0;

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ('name' => $self->{lhost});
    my @properties = ('config.fileSystemVolume.mountInfo', 'runtime.connectionState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::host_state($self->{obj_esxd}, $self->{lhost}, 
                                                $$result[0]->{'runtime.connectionState'}->val) == 0);

    my %uuid_list = ();
    #my %disk_name = ();
    my $instances = [];
    if ($self->{ds} eq '') {
        $instances =  ['*'];
    }
    foreach (@{$$result[0]->{'config.fileSystemVolume.mountInfo'}}) {
        if ($_->volume->isa('HostVmfsVolume')) {
            if ($self->{ds} ne '') {
                if ($self->{filter} == 0 && $_->volume->name !~ /^\Q$self->{ds}\E$/) {
                    next;
                } elsif ($self->{filter} == 1 && $_->volume->name !~ /$self->{ds}/) {
                    next;
                }
            }
            
            $filter_ok = 1;
            $uuid_list{$_->volume->uuid} = $_->volume->name;
            push @$instances, $_->volume->uuid;
            # Not need. We are on Datastore level (not LUN level)
            #foreach my $extent (@{$_->volume->extent}) {
            #    $disk_name{$extent->diskName} = $_->volume->name;
            #}
        }
        if ($_->volume->isa('HostNasVolume')) {
            if ($self->{ds} ne '') {
                if ($self->{filter} == 0 && $_->volume->name !~ /^\Q$self->{ds}\E$/) {
                    next;
                } elsif ($self->{filter} == 1 && $_->volume->name !~ /$self->{ds}/) {
                    next;
                }
            }

            $filter_ok = 1;
            $uuid_list{basename($_->mountInfo->path)} = $_->volume->name;
            push @$instances, basename($_->mountInfo->path);
        }
    }
    
    if ($self->{ds} ne '' and $filter_ok == 0) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status). "|Can't get a datastore with the filter '$self->{ds}'.\n");
        return ;
    }

    # Vsphere >= 4.1
    # You get counters even if datastore is disconnect...
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $$result[0], 
                        [{'label' => 'datastore.totalReadLatency.average', 'instances' => $instances},
                        {'label' => 'datastore.totalWriteLatency.average', 'instances' => $instances}],
                        $self->{obj_esxd}->{perfcounter_speriod});
    return if (centreon::esxd::common::performance_errors($self->{obj_esxd}, $values) == 1);

    my $status = 0; # OK
    my $output = '';
    my $output_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output_critical = '';
    my $output_critical_append = '';
    my $perfdata = '';
    foreach (keys %uuid_list) {
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

            $perfdata .= " 'trl_" . $uuid_list{$_} . "'=" . $read_counter . "ms 'twl_" . $uuid_list{$_} . "'=" . $write_counter . 'ms';
        }
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
