
package centreon::esxd::cmdswapvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'swapvm';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{vm_hostname}) && $options{arguments}->{vm_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: vm hostname cannot be null");
        return 1;
    }
    if (defined($options{arguments}->{disconnect_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{disconnect_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for disconnect status '" . $options{arguments}->{disconnect_status} . "'");
        return 1;
    }
    if (defined($options{arguments}->{nopoweredon_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{nopoweredon_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for nopoweredon status '" . $options{arguments}->{nopoweredon_status} . "'");
        return 1;
    }
    if (($options{manager}->{perfdata}->threshold_validate(label => 'warning', value => $options{arguments}->{warning})) == 0) {
       $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Argument error: wrong value for warning value '" . $options{arguments}->{warning} . "'.");
       return 1;
    }
    if (($options{manager}->{perfdata}->threshold_validate(label => 'critical', value => $options{arguments}->{critical})) == 0) {
       $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                               short_msg => "Argument error: wrong value for critical value '" . $options{arguments}->{critical} . "'.");
       return 1;
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
    $self->{manager}->{perfdata}->threshold_validate(label => 'warning', value => $options{arguments}->{warning});
    $self->{manager}->{perfdata}->threshold_validate(label => 'critical', value => $options{arguments}->{critical});
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
    if (defined($self->{vm_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{vm_hostname}\E$/;
    } elsif (!defined($self->{vm_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{vm_hostname}/;
    }
    if (defined($self->{filter_description}) && $self->{filter_description} ne '') {
        $filters{'config.annotation'} = qr/$self->{filter_description}/;
    }
    
    my @properties = ('name', 'runtime.connectionState', 'runtime.powerState');
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }
    
    my $result = centreon::esxd::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => \%filters);
    return if (!defined($result));
    
    my $values = centreon::esxd::common::generic_performance_values_historic($self->{connector},
                        $result, 
                        [{label => 'mem.swapinRate.average', instances => ['']},
                         {label => 'mem.swapoutRate.average', instances => ['']}],
                        $self->{connector}->{perfcounter_speriod},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::esxd::common::performance_errors($self->{connector}, $values) == 1);
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All swap rate usages are ok"));
    }
    
    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::vm_state(connector => $self->{connector},
                                                  hostname => $entity_view->{name}, 
                                                  state => $entity_view->{'runtime.connectionState'}->val,
                                                  power => $entity_view->{'runtime.powerState'}->val,
                                                  status => $self->{disconnect_status},
                                                  powerstatus => $self->{nopoweredon_status},
                                                  multiple => $multiple) == 0);
        my $entity_value = $entity_view->{mo_ref}->{value};    

        # KBps
        my $swap_in = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.swapinRate.average'}->{'key'} . ":"}[0])) * 1024;
        my $swap_out = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.swapoutRate.average'}->{'key'} . ":"}[0])) * 1024;

        my $exit1 = $self->{manager}->{perfdata}->threshold_check(value => $swap_in, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{manager}->{perfdata}->threshold_check(value => $swap_out, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my $exit = $self->{manager}->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
        my ($swap_in_value, $swap_in_unit) = $self->{manager}->{perfdata}->change_bytes(value => $swap_in);
        my ($swap_out_value, $swap_out_unit) = $self->{manager}->{perfdata}->change_bytes(value => $swap_out);
        
        my $prefix_msg = "'$entity_view->{name}'";
        if (defined($self->{display_description}) && defined($entity_view->{'config.annotation'}) &&
            $entity_view->{'config.annotation'} ne '') {
            $prefix_msg .= ' [' . centreon::esxd::common::strip_cr(value => $entity_view->{'config.annotation'}) . ']';
        }
        
        $self->{manager}->{output}->output_add(long_msg => sprintf("%s Swap In: %s Swap Out: %s", 
                                            $prefix_msg,
                                            $swap_in_value . " " . $swap_in_unit . "/s",
                                            $swap_out_value . " " . $swap_out_unit . "/s"));
        if ($multiple == 0 ||
            !$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
             $self->{manager}->{output}->output_add(severity => $exit,
                                                    short_msg => sprintf("%s Swap In: %s Swap Out: %s", 
                                            $prefix_msg,
                                            $swap_in_value . " " . $swap_in_unit . "/s",
                                            $swap_out_value . " " . $swap_out_unit . "/s"));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $entity_view->{name} if ($multiple == 1);
        $self->{manager}->{output}->perfdata_add(label => 'swap_in' . $extra_label, unit => 'B/s',
                                                 value => $swap_in,
                                                 warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                 critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                 min => 0);
        $self->{manager}->{output}->perfdata_add(label => 'swap_out' . $extra_label, unit => 'B/s',
                                                 value => $swap_out,
                                                 warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                                 critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                                 min => 0);
    }
}

1;
