
package centreon::esxd::cmdnethost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'nethost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($host, $pnic, $filter, $warn, $crit) = @_;

    if (!defined($host) || $host eq "") {
        $self->{logger}->writeLogError("ARGS error: need hostname");
        return 1;
    }
    if (!defined($pnic) || $pnic eq "") {
        $self->{logger}->writeLogError("ARGS error: need physical nic name");
        return 1;
    }
    if (defined($warn) && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be a positive number");
        return 1;
    }
    if (defined($crit) && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: crit threshold must be a positive number");
        return 1;
    }
    if (defined($warn) && defined($crit) && $warn > $crit) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be lower than crit threshold");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lhost} = $_[0];
    $self->{pnic} = $_[1];
    $self->{filter} = (defined($_[2]) && $_[2] == 1) ? 1 : 0;
    $self->{warn} = (defined($_[3]) ? $_[3] : 80);
    $self->{crit} = (defined($_[4]) ? $_[4] : 90);
    $self->{skip_errors} = (defined($_[5]) && $_[5] == 1) ? 1 : 0;
}

sub run {
    my $self = shift;

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ('name' => $self->{lhost});
    my @properties = ('config.network.pnic', 'runtime.connectionState', 'config.network.vswitch');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::host_state($self->{obj_esxd}, $self->{lhost}, 
                                                $$result[0]->{'runtime.connectionState'}->val) == 0);
    
    my %nic_in_vswitch = ();
    my %pnic_def_up = ();
    my %pnic_def_down = ();
    my $instances = [];
    my $filter_ok = 0;
    
    # Get Name from vswitch
    foreach (@{$$result[0]->{'config.network.vswitch'}}) {
        foreach my $keynic (@{$_->pnic}) {
            $nic_in_vswitch{$keynic} = 1;
        }
    }

    foreach (@{$$result[0]->{'config.network.pnic'}}) {
        # Not in vswitch. Skip
        if (!defined($nic_in_vswitch{$_->key})) {
            next;
        }

        # Check filter
        next if ($self->{filter} == 0 && $_->device !~ /^\Q$self->{pnic}\E$/);
        next if ($self->{filter} == 1 && $_->device !~ /$self->{pnic}/);
        
        $filter_ok = 1;
        if (defined($_->linkSpeed)) {
            $pnic_def_up{$_->device} = $_->linkSpeed->speedMb;
            push @$instances, $_->device;
        } else {
            $pnic_def_down{$_->device} = 1;
        }
    }
    
    if ($filter_ok == 0) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't get physical nic with filter '$self->{pnic}'. (or physical nic not in a vswitch)\n");
        return ;
    }
    if ($#${instances} == -1) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Link(s) '" . join("','", keys %pnic_def_down) . "' is(are) down.\n");
        return ;
    }


    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $result, 
                        [{'label' => 'net.received.average', 'instances' => $instances},
                         {'label' => 'net.transmitted.average', 'instances' => $instances}],
                        $self->{obj_esxd}->{perfcounter_speriod});
    return if (centreon::esxd::common::performance_errors($self->{obj_esxd}, $values) == 1);

    my $status = 0; # OK
    my $output = "";
    my $output_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output_critical = '';
    my $output_critical_append = '';
    my $output_unknown = '';
    my $output_unknown_append = '';
    my $output_ok_unit = '';
    my $perfdata = '';
    
    my @nic_downs = keys %pnic_def_down;
    if ($#nic_downs >= 0) {
        if ($self->{skip_errors} == 0 || $self->{filter} == 0) {
            $status = centreon::esxd::common::errors_mask($status, 'UNKNOWN');
        }
        centreon::esxd::common::output_add(\$output_unknown, \$output_unknown_append, ", ",
                     "Link(s) '" . join("','", @nic_downs) . "' is(are) down");
    }

    foreach (keys %pnic_def_up) {
    
        my $traffic_in = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'net.received.average'}->{'key'} . ":" . $_}[0]));    
        my $traffic_out = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'net.transmitted.average'}->{'key'} . ":" . $_}[0]));
    
        $output_ok_unit = "Traffic In : " . centreon::esxd::common::simplify_number($traffic_in / 1024) . " MB/s (" . centreon::esxd::common::simplify_number($traffic_in / 1024 * 100 / $pnic_def_up{$_}) . " %), Out : " . centreon::esxd::common::simplify_number($traffic_out / 1024) . " MB/s (" . centreon::esxd::common::simplify_number($traffic_out / 1024 * 100 / $pnic_def_up{$_}) . " %)";
    
        if (($traffic_in / 1024 * 100 / $pnic_def_up{$_}) >= $self->{crit} || ($traffic_out / 1024 * 100 / $pnic_def_up{$_}) >= $self->{crit}) {
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ". ",
                        "'$_' Traffic In : " . centreon::esxd::common::simplify_number($traffic_in / 1024) . " MB/s (" . centreon::esxd::common::simplify_number($traffic_in / 1024 * 100 / $pnic_def_up{$_}) . " %), Out : " . centreon::esxd::common::simplify_number($traffic_out / 1024) . " MB/s (" . centreon::esxd::common::simplify_number($traffic_out / 1024 * 100 / $pnic_def_up{$_}) . " %)");
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
        } elsif (($traffic_in / 1024 * 100 / $pnic_def_up{$_}) >= $self->{warn} || ($traffic_out / 1024 * 100 / $pnic_def_up{$_}) >= $self->{warn}) {
            centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ". ",
                        "'$_' Traffic In : " . centreon::esxd::common::simplify_number($traffic_in / 1024) . " MB/s (" . centreon::esxd::common::simplify_number($traffic_in / 1024 * 100 / $pnic_def_up{$_}) . " %), Out : " . centreon::esxd::common::simplify_number($traffic_out / 1024) . " MB/s (" . centreon::esxd::common::simplify_number($traffic_out / 1024 * 100 / $pnic_def_up{$_}) . " %)");
            $status = centreon::esxd::common::errors_mask($status, 'WARNING');
        }
        
        my $warn_perfdata = ($pnic_def_up{$_} * $self->{warn} / 100) * 1024 * 1024;
        my $crit_perfdata = ($pnic_def_up{$_} * $self->{crit} / 100) * 1024 * 1024;
        
        if ($self->{filter} == 1) {
            $perfdata .= " 'traffic_in_" . $_ . "'=" . ($traffic_in * 1024) . "B/s;$warn_perfdata;$crit_perfdata;0; 'traffic_out_" . $_ . "'=" . (($traffic_out * 1024)) . "B/s;$warn_perfdata;$crit_perfdata;0;";
        } else {
            $perfdata .= " traffic_in=" . ($traffic_in * 1024) . "B/s;$warn_perfdata;$crit_perfdata;0; traffic_out=" . (($traffic_out * 1024)) . "B/s;$warn_perfdata;$crit_perfdata;0;";
        }
    }

    if ($output_unknown ne "") {
        $output .= $output_append . "UNKNOWN - $output_unknown";
        $output_append = ". ";
    }
    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - $output_critical";
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - $output_warning";
    }
    if ($status == 0) {
        if ($self->{filter} == 1) {
            $output .= $output_append . "All traffics are ok";
        } else {
            $output .= $output_append . $output_ok_unit;
        }
    }
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output|$perfdata\n");
}

1;
