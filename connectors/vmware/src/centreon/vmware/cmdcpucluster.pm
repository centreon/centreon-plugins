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

package centreon::vmware::cmdcpucluster;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'cpucluster';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{cluster_name}) && $options{arguments}->{cluster_name} eq '') {
        centreon::vmware::common::set_response(code => 100, short_message => 'Argument error: cluster name cannot be null');
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

    my $filters = $self->build_filter(label => 'name', search_option => 'cluster_name', is_regexp => 'filter');
    my @properties = ('name');
    my $views = centreon::vmware::common::search_entities(command => $self, view_type => 'ClusterComputeResource', properties => \@properties, filter => $filters);
    return if (!defined($views));

    my $values = centreon::vmware::common::generic_performance_values_historic(
        $self->{connector},
        $views,
        [
            { label => 'cpu.usage.average',    instances => [''] },
            { label => 'cpu.usagemhz.average', instances => [''] }
        ],
        $self->{connector}->{perfcounter_speriod},
        sampling_period => $self->{sampling_period},
        time_shift => $self->{time_shift},
        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1
    );
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);

    my $interval_min = centreon::vmware::common::get_interval_min(
        speriod => $self->{connector}->{perfcounter_speriod}, 
        sampling_period => $self->{sampling_period},
        time_shift => $self->{time_shift}
    );

    my $data = {};
    foreach my $view (@$views) {
        my $entity_value = $view->{mo_ref}->{value};
        $data->{$entity_value} = { name => $view->{name} };

        my $total_cpu_average = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{ $self->{connector}->{perfcounter_cache}->{'cpu.usage.average'}->{key} . ':' } * 0.01));
        my $total_cpu_mhz_average = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{ $self->{connector}->{perfcounter_cache}->{'cpu.usagemhz.average'}->{key} . ':' }));

        $data->{$entity_value}->{'interval_min'} = $interval_min;
        $data->{$entity_value}->{'cpu.usage.average'} = $total_cpu_average;
        $data->{$entity_value}->{'cpu.usagemhz.average'} = $total_cpu_mhz_average;
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
