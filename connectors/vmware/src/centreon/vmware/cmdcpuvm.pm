# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets 
# the needs in IT infrastructure and application monitoring for 
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::cmdcpuvm;

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'cpuvm';
    
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
    foreach my $label (('warning_usagemhz', 'critical_usagemhz', 'warning_usage', 'critical_usage', 'warning_ready', 'critical_ready')) {
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
    $self->{manager} = centreon::vmware::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
    foreach my $label (('warning_usagemhz', 'critical_usagemhz', 'warning_usage', 'critical_usage', 'warning_ready', 'critical_ready')) {
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
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => \%filters);
    return if (!defined($result));

    my @instances = ('*');
    my $values = centreon::vmware::common::generic_performance_values_historic($self->{connector},
                        $result, 
                        [{'label' => 'cpu.usage.average', 'instances' => \@instances},
                         {'label' => 'cpu.usagemhz.average', 'instances' => \@instances},
                         {'label' => 'cpu.ready.summation', 'instances' => \@instances}],
                        $self->{connector}->{perfcounter_speriod},
                        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All cpu usages are ok"));
    }
    
    my $interval_sec = $self->{connector}->{perfcounter_speriod};
    if (defined($self->{sampling_period}) && $self->{sampling_period} ne '') {
        $interval_sec = $self->{sampling_period};
    }
    my $interval_min = centreon::vmware::common::get_interval_min(speriod => $self->{connector}->{perfcounter_speriod}, 
                                                                  sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift});
    foreach my $entity_view (@$result) {
        next if (centreon::vmware::common::vm_state(connector => $self->{connector},
                                                  hostname => $entity_view->{name}, 
                                                  state => $entity_view->{'runtime.connectionState'}->val,
                                                  power => $entity_view->{'runtime.powerState'}->val,
                                                  status => $self->{disconnect_status},
                                                  powerstatus => $self->{nopoweredon_status},
                                                  multiple => $multiple) == 0);
        my $entity_value = $entity_view->{mo_ref}->{value};
        my $total_cpu_average = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'cpu.usage.average'}->{'key'} . ":"} * 0.01));
        my $total_cpu_mhz_average = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'cpu.usagemhz.average'}->{'key'} . ":"}));
        my $total_cpu_ready = centreon::vmware::common::simplify_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'cpu.ready.summation'}->{'key'} . ":"} / ($interval_sec * 1000) * 100);
        
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        my $extra_label = '';
        $extra_label = '_' . $entity_view->{name} if ($multiple == 1);
        foreach my $entry (({ value => $total_cpu_average, label => 'usage', output => 'Total Average CPU usage %s %%',
                              perf_label => 'cpu_total', perf_min => 0, perf_max => 100, perf_unit => '%' }, 
                            { value => $total_cpu_mhz_average, label => 'usagemhz', output => 'Total Average CPU %s Mhz',
                              perf_label => 'cpu_total_MHz', perf_min => 0, perf_unit => 'MHz'}, 
                            { value => $total_cpu_ready, label => 'ready', output => 'CPU ready %s %%',
                              perf_label => 'cpu_ready', perf_min => 0, perf_unit => '%' })) {
            my $exit = $self->{manager}->{perfdata}->threshold_check(value => $entry->{value}, threshold => [ { label => 'critical_' . $entry->{label}, exit_litteral => 'critical' }, { label => 'warning_' . $entry->{label}, exit_litteral => 'warning' } ]);
            push @exits, $exit;
 
            my $output = sprintf($entry->{output}, $entry->{value});
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || $multiple == 0) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $self->{manager}->{output}->perfdata_add(label => $entry->{perf_label} . $extra_label, unit => $entry->{perf_unit},
                                          value => $entry->{value},
                                          warning => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'warning_' . $entry->{label}),
                                          critical => $self->{manager}->{perfdata}->get_perfdata_for_output(label => 'critical_' . $entry->{label}),
                                          min => $entry->{perf_min}, max => $entry->{perf_max});
        }
        
        $long_msg .= ' on last ' . $interval_min . ' min';
        my $prefix_msg = "'$entity_view->{name}'";
        if (defined($self->{display_description}) && defined($entity_view->{'config.annotation'}) &&
            $entity_view->{'config.annotation'} ne '') {
            $prefix_msg .= ' [' . centreon::vmware::common::strip_cr(value => $entity_view->{'config.annotation'}) . ']';
        }

        $self->{manager}->{output}->output_add(long_msg => "$prefix_msg $long_msg");
        my $exit = $self->{manager}->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{manager}->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{manager}->{output}->output_add(severity => $exit,
                                                   short_msg => "$prefix_msg $short_msg"
                                                   );
        }
        if ($multiple == 0) {
            $self->{manager}->{output}->output_add(short_msg => "$prefix_msg $long_msg");
        }
        
        foreach my $id (sort { my ($cida, $cia) = split /:/, $a;
                   my ($cidb, $cib) = split /:/, $b;
                               $cia = -1 if (!defined($cia) || $cia eq "");
                               $cib = -1 if (!defined($cib) || $cib eq "");
                   $cia <=> $cib} keys %{$values->{$entity_value}}) {
            my ($counter_id, $instance) = split /:/, $id;
            next if ($self->{connector}->{perfcounter_cache}->{'cpu.usagemhz.average'}->{key} != $counter_id);
            if ($instance ne "") {
                $self->{manager}->{output}->perfdata_add(label => 'cpu_' . $instance . '_MHz' . $extra_label, unit => 'MHz',
                                                         value => centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$id})),
                                                         min => 0);
            }
        }
    }
}

1;
