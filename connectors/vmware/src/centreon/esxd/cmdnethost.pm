
package centreon::esxd::cmdnethost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'nethost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}


sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: esx hostname cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{nic_name}) && $options{arguments}->{nic_name} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: nic name cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{disconnect_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{disconnect_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for disconnect status '" . $options{arguments}->{disconnect_status} . "'");
        return 1;
    }
    if (defined($options{arguments}->{link_down_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{link_down_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for link down status '" . $options{arguments}->{link_down_status} . "'");
        return 1;
    }
    foreach my $label (('warning_in', 'critical_in', 'warning_out', 'critical_out')) {
        if (($options{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label})) == 0) {
            $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                    short_msg => "Argument error: wrong value for $label value '" . $options{arguments}->{$label} . "'.");
            return 1;
        }
    }
    return 0;
}

sub initArgs {
    my ($self, %options) = @_;
    
    foreach (keys %{$options{arguments}}) {
        $self->{$_} = $options{arguments}->{$_};
    }
    $self->{manager} = centreon::esxd::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
    foreach my $label (('warning_in', 'critical_in', 'warning_out', 'critical_out')) {
        $self->{manager}->{perfdata}->threshold_validate(label => $label, value => $options{arguments}->{$label});
    }
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;

    if (!($self->{connector}->{perfcounter_speriod} > 0)) {
        $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Can't retrieve perf counters");
        return ;
    }

    my %filters = ();
    my $multiple = 0;
    if (defined($self->{esx_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{esx_hostname}\E$/;
    } elsif (!defined($self->{esx_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{esx_hostname}/;
    }
    my @properties = ('name', 'config.network.pnic', 'runtime.connectionState', 'config.network.vswitch', 'config.network.proxySwitch');
    my $result = centreon::esxd::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => \%filters);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All traffics are ok"));
    }
    
    my $pnic_def_up = {};
    my $pnic_def_down = {};
    my $query_perfs = [];
    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::host_state(connector => $self->{connector},
                                                    hostname => $entity_view->{name}, 
                                                    state => $entity_view->{'runtime.connectionState'}->val,
                                                    status => $self->{disconnect_status},
                                                    multiple => $multiple) == 0);
        $pnic_def_up->{$entity_view->{mo_ref}->{value}} = {};
        $pnic_def_down->{$entity_view->{mo_ref}->{value}} = {};
        my %nic_in_vswitch = ();
        my $instances = [];
        my $filter_ok = 0;
        
        # Get Name from vswitch
        if (defined($entity_view->{'config.network.vswitch'})) {
            foreach (@{$entity_view->{'config.network.vswitch'}}) {
                next if (!defined($_->{pnic}));
                foreach my $keynic (@{$_->{pnic}}) {
                    $nic_in_vswitch{$keynic} = 1;
                }
            }
        }
        # Get Name from proxySwitch
        if (defined($entity_view->{'config.network.proxySwitch'})) {
            foreach (@{$entity_view->{'config.network.proxySwitch'}}) {
                next if (!defined($_->{pnic}));
                foreach my $keynic (@{$_->{pnic}}) {
                    $nic_in_vswitch{$keynic} = 1;
                }
            }
        }

        foreach (@{$entity_view->{'config.network.pnic'}}) {
            # Not in vswitch. Skip
            next if (!defined($nic_in_vswitch{$_->key}));

            # Check filter
            if (defined($self->{nic_name}) && !defined($self->{filter_nic}) && $_->device ne $self->{nic_name}) {
                next;
            } elsif (defined($self->{nic_name}) && defined($self->{filter_nic}) && $_->device !~ /$self->{nic_name}/) {
                next;
            }
            $filter_ok = 1;
            if (defined($_->linkSpeed)) {
                $pnic_def_up->{$entity_view->{mo_ref}->{value}}->{$_->device} = $_->linkSpeed->speedMb;
                push @$instances, $_->device;
            } else {
                $pnic_def_down->{$entity_view->{mo_ref}->{value}}->{$_->device} = 1;
            }
        }
        
        if ($filter_ok == 0) {
           $self->{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                  short_msg => sprintf("%s can't get physical nic with filter '%s'. (or physical nic not in a 'vswitch' or 'dvswitch'",
                                                                        $entity_view->{name}, $self->{nic_name}));
           next;
        }
        if (scalar(@${instances}) == 0 && 
            ($multiple == 0 || ($multiple == 1 && !$self->{manager}->{output}->is_status(value => $self->{link_down_status}, compare => 'ok', litteral => 1)))) {
            $self->{manager}->{output}->output_add(severity => $self->{link_down_status},
                                                   short_msg => sprintf("%s Link(s) '%s' is(are) down",
                                                                        $entity_view->{name}, join("','", keys %{$pnic_def_down->{$entity_view->{mo_ref}->{value}}})));
            next;
        }
        
        push @$query_perfs, {
                              entity => $entity_view,
                              metrics => [ 
                                {label => 'net.received.average', instances => $instances},
                                {label => 'net.transmitted.average', instances => $instances}
                              ]
                             };
    }  
    
    # Nothing to retrieve. problem before already.
    return if (scalar(@$query_perfs) == 0);
        
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{connector},
                        undef, 
                        $query_perfs,
                        $self->{connector}->{perfcounter_speriod},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::esxd::common::performance_errors($self->{connector}, $values) == 1);
    
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        if (scalar(keys %{$pnic_def_down->{$entity_value}}) > 0 && 
            ($multiple == 0 || !$self->{manager}->{output}->is_status(value => $self->{link_down_status}, compare => 'ok', litteral => 1))) {
            $self->{manager}->{output}->output_add(severity => $self->{link_down_status},
                                                   short_msg => sprintf("%s Link(s) '%s' is(are) down",
                                                                        $entity_view->{name}, join("','", keys %{$pnic_def_down->{$entity_value}})));
        }
        
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$pnic_def_up->{$entity_value}}) {
            # KBps
            my $traffic_in = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'net.received.average'}->{key} . ":" . $_}[0])) * 1024 * 8;    
            my $traffic_out = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'net.transmitted.average'}->{key} . ":" . $_}[0])) * 1024 * 8;
            my $interface_speed = $pnic_def_up->{$entity_value}->{$_} * 1024 * 1024;
            my $in_prct = $traffic_in  * 100 / $interface_speed;
            my $out_prct = $traffic_out * 100 / $interface_speed;
           
            my $exit1 = $self->{manager}->{perfdata}->threshold_check(value => $in_prct, threshold => [ { label => 'critical_in', exit_litteral => 'critical' }, { label => 'warning_in', exit_litteral => 'warning' } ]);
            my $exit2 = $self->{manager}->{perfdata}->threshold_check(value => $out_prct, threshold => [ { label => 'critical_out', exit_litteral => 'critical' }, { label => 'warning_out', exit_litteral => 'warning' } ]);

            my ($in_value, $in_unit) = $self->{manager}->{perfdata}->change_bytes(value => $traffic_in, network => 1);
            my ($out_value, $out_unit) = $self->{manager}->{perfdata}->change_bytes(value => $traffic_out, network => 1);
            my $exit = $self->{manager}->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
            push @exits, $exit;
 
            my $output = sprintf("Interface '%s' Traffic In : %s/s (%.2f %%), Out : %s/s (%.2f %%) ", $_,
                                           $in_value . $in_unit, $in_prct,
                                           $out_value . $out_unit, $out_prct);
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || $multiple == 0) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }

            my $extra_label = '';
            $extra_label = '_' . $entity_view->{name} if ($multiple == 1);
            $self->{manager}->{output}->perfdata_add(label => 'traffic_in' . $extra_label, unit => 'b/s',
                                          value => sprintf("%.2f", $traffic_in),
                                          warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning-in', total => $interface_speed),
                                          critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical-in', total => $interface_speed),
                                          min => 0, max => $interface_speed);
            $self->{manager}->{output}->perfdata_add(label => 'traffic_out' . $extra_label, unit => 'b/s',
                                          value => sprintf("%.2f", $traffic_out),
                                          warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning-out', total => $interface_speed),
                                          critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical-out', total => $interface_speed),
                                          min => 0, max => $interface_speed);
        }
        
        $self->{manager}->{output}->output_add(long_msg => "'$entity_view->{name}' $long_msg");
        my $exit = $self->{manager}->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{manager}->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{manager}->{output}->output_add(severity => $exit,
                                                   short_msg => "'$entity_view->{name}' $short_msg"
                                                   );
        }
        if ($multiple == 0) {
            $self->{manager}->{output}->output_add(short_msg => "'$entity_view->{name}' $long_msg");
        }
    }
}

1;
