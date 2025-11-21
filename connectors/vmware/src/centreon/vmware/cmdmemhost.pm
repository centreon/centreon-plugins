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

package centreon::vmware::cmdmemhost;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'memhost';
    
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
    my @properties = ('name', 'summary.hardware.memorySize', 'runtime.connectionState');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => $filters);
    return if (!defined($result));

    my $performances = [{'label' => 'mem.consumed.average', 'instances' => ['']},
                        {'label' => 'mem.overhead.average', 'instances' => ['']}];
    if (!defined($self->{no_memory_state})) {
        push @{$performances}, {'label' => 'mem.state.latest', 'instances' => ['']};
    }
    my $values = centreon::vmware::common::generic_performance_values_historic($self->{connector},
                        $result, $performances,
                        $self->{connector}->{perfcounter_speriod},
                        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);
    
    # for mem.state:
    # 0   (high)  Free memory >= 6% of machine memory minus Service Console memory.
    # 1   (soft)  4%
    # 2   (hard)  2%
    # 3   (low)  1%
    my %mapping_state = (0 => 'high', 1 => 'soft', 2 => 'hard', 3 => 'low');
    
    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};                          
        
        $data->{$entity_value} = { name => $entity_view->{name}, state => $entity_view->{'runtime.connectionState'}->val };
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);
        
        my $memory_size = $entity_view->{'summary.hardware.memorySize'}; # in B

        # in KB
        my $mem_used = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.consumed.average'}->{'key'} . ":"})) * 1024;
        my $mem_overhead = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.overhead.average'}->{'key'} . ":"})) * 1024;
        my $mem_state;
        if (!defined($self->{no_memory_state})) {
            $mem_state = centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.state.latest'}->{'key'} . ":"});
        }
        
        $data->{$entity_value}->{mem_size} = $memory_size;
        $data->{$entity_value}->{'mem.consumed.average'} = $mem_used;
        $data->{$entity_value}->{'mem.overhead.average'} = $mem_overhead;
        $data->{$entity_value}->{mem_state_str} = defined($mem_state) ? $mapping_state{$mem_state} : undef;
        $data->{$entity_value}->{mem_state} = defined($mem_state) ? $mem_state : undef;
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
