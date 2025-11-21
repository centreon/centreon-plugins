# Copyright 2024 Centreon (http://www.centreon.com/)
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

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'cpuvm';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{vm_hostname}) && $options{arguments}->{vm_hostname} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: vm hostname cannot be null");
        return 1;
    }

    return 0;
}

sub run {
    my $self = shift;

    if (!($self->{connector}->{perfcounter_speriod} > 0)) {
        centreon::vmware::common::set_response(code => -1, short_message => "Can't retrieve perf counters");
        return ;
    }

    my $filters = $self->build_filter(label => 'name', search_option => 'vm_hostname', is_regexp => 'filter');
    $self->add_filter(filters => $filters, label => 'config.annotation', search_option => 'filter_description');
    $self->add_filter(filters => $filters, label => 'config.guestFullName', search_option => 'filter_os');
    $self->add_filter(filters => $filters, label => 'config.uuid', search_option => 'filter_uuid');
    
    my @properties = ('name', 'runtime.connectionState', 'runtime.powerState');
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => $filters);
    return if (!defined($result));

    my @instances = ('*');
    my $values = centreon::vmware::common::generic_performance_values_historic(
        $self->{connector},
        $result, 
        [
            {'label' => 'cpu.usage.average', 'instances' => \@instances},
            {'label' => 'cpu.usagemhz.average', 'instances' => \@instances},
            {'label' => 'cpu.ready.summation', 'instances' => \@instances}
        ],
        $self->{connector}->{perfcounter_speriod},
        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1
    );
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);
    
    my $interval_sec = $self->{connector}->{perfcounter_speriod};
    if (defined($self->{sampling_period}) && $self->{sampling_period} ne '') {
        $interval_sec = $self->{sampling_period};
    }
    my $interval_min = centreon::vmware::common::get_interval_min(
        speriod => $self->{connector}->{perfcounter_speriod}, 
        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift}
    );

    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};

        $data->{$entity_value} = {
            name => $entity_view->{name},
            connection_state => $entity_view->{'runtime.connectionState'}->val, 
            power_state => $entity_view->{'runtime.powerState'}->val,
            'config.annotation' => defined($entity_view->{'config.annotation'}) ? $entity_view->{'config.annotation'} : undef,
        };
        
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);
        next if (centreon::vmware::common::is_running(power => $entity_view->{'runtime.powerState'}->val) == 0);
        
        my $total_cpu_average = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'cpu.usage.average'}->{'key'} . ":"} * 0.01));
        my $total_cpu_mhz_average = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'cpu.usagemhz.average'}->{'key'} . ":"}));
        my $total_cpu_ready = centreon::vmware::common::simplify_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'cpu.ready.summation'}->{'key'} . ":"} / ($interval_sec * 1000) * 100);
        
        $data->{$entity_value}->{'cpu.usage.average'} = $total_cpu_average;
        $data->{$entity_value}->{'cpu.usagemhz.average'} = $total_cpu_mhz_average;
        $data->{$entity_value}->{'cpu_ready'} = $total_cpu_ready;
        $data->{$entity_value}->{'interval_min'} = $interval_min;
        $data->{$entity_value}->{'cpu'} = {};
        
        foreach my $id (sort { my ($cida, $cia) = split /:/, $a;
                   my ($cidb, $cib) = split /:/, $b;
                               $cia = -1 if (!defined($cia) || $cia eq "");
                               $cib = -1 if (!defined($cib) || $cib eq "");
                   $cia <=> $cib} keys %{$values->{$entity_value}}) {
            my ($counter_id, $instance) = split /:/, $id;
            next if ($self->{connector}->{perfcounter_cache}->{'cpu.usagemhz.average'}->{key} != $counter_id);
            if ($instance ne "") {
                $data->{$entity_value}->{cpu}->{$instance} = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$id}));
            }
        }
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
