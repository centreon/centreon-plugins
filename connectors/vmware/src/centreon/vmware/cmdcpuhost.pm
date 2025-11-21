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

package centreon::vmware::cmdcpuhost;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'cpuhost';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: esx hostname cannot be null");
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

    my $filters = $self->build_filter(label => 'name', search_option => 'esx_hostname', is_regexp => 'filter');
    my @properties = ('name', 'runtime.connectionState', 'summary.hardware.numCpuCores', 'summary.hardware.cpuMhz');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => $filters);
    return if (!defined($result));

    my @instances = ('*');
    my $values = centreon::vmware::common::generic_performance_values_historic(
        $self->{connector},
        $result, 
        [
            { label => 'cpu.usage.average',    'instances' => \@instances},
            { label => 'cpu.usagemhz.average', 'instances' => \@instances}
        ],
        $self->{connector}->{perfcounter_speriod},
        sampling_period => $self->{sampling_period},
        time_shift => $self->{time_shift},
        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1
    );
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);

    my $interval_min = centreon::vmware::common::get_interval_min(
        speriod => $self->{connector}->{perfcounter_speriod}, 
        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift}
    );

    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        $data->{$entity_value} = { name => $entity_view->{name}, state => $entity_view->{'runtime.connectionState'}->val };
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);

        my $total_cpu_average = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'cpu.usage.average'}->{'key'} . ":"} * 0.01));
        my $total_cpu_mhz_average = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'cpu.usagemhz.average'}->{'key'} . ":"}));
        
        $data->{$entity_value}->{'interval_min'} = $interval_min;
        $data->{$entity_value}->{'cpu.usage.average'} = $total_cpu_average;
        $data->{$entity_value}->{'cpu.usagemhz.average'} = $total_cpu_mhz_average;
        $data->{$entity_value}->{'numCpuCores'} = $entity_view->{'summary.hardware.numCpuCores'};
        $data->{$entity_value}->{'cpuMhz'} = $entity_view->{'summary.hardware.cpuMhz'};
        $data->{$entity_value}->{'cpu'} = {};

        foreach my $id (sort { my ($cida, $cia) = split /:/, $a;
                       my ($cidb, $cib) = split /:/, $b;
                                   $cia = -1 if (!defined($cia) || $cia eq "");
                                   $cib = -1 if (!defined($cib) || $cib eq "");
                       $cia <=> $cib} keys %{$values->{$entity_value}}) {
            my ($counter_id, $instance) = split /:/, $id;
            if ($instance ne "") {
                $data->{$entity_value}->{cpu}->{$instance} = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$id}) * 0.01);
            }
        }
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
