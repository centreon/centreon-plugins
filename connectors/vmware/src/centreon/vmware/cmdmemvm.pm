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

package centreon::vmware::cmdmemvm;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'memvm';
    
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
    
    my @properties = ('name', 'summary.config.memorySizeMB', 'runtime.connectionState', 'runtime.powerState');
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    my $values = centreon::vmware::common::generic_performance_values_historic($self->{connector},
                        $result, 
                        [{label => 'mem.active.average', instances => ['']},
                         {label => 'mem.overhead.average', instances => ['']},
                         {label => 'mem.vmmemctl.average', instances => ['']},
                         {label => 'mem.consumed.average', instances => ['']},
                         {label => 'mem.shared.average', instances => ['']}],
                        $self->{connector}->{perfcounter_speriod},
                        sampling_period => $self->{sampling_period}, time_shift => $self->{time_shift},
                        skip_undef_counter => 1, multiples => 1, multiples_result_by_entity => 1);
    return if (centreon::vmware::common::performance_errors($self->{connector}, $values) == 1);
    
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
                
        # in KB
        my $mem_consumed = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.consumed.average'}->{'key'} . ":"})) * 1024;
        my $mem_active = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.active.average'}->{'key'} . ":"})) * 1024;
        my $mem_overhead = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.overhead.average'}->{'key'} . ":"})) * 1024;
        my $mem_ballooning = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.vmmemctl.average'}->{'key'} . ":"})) * 1024;
        my $mem_shared = centreon::vmware::common::simplify_number(centreon::vmware::common::convert_number($values->{$entity_value}->{$self->{connector}->{perfcounter_cache}->{'mem.shared.average'}->{'key'} . ":"})) * 1024;        
        
        $data->{$entity_value}->{'memory_size'} = $entity_view->{'summary.config.memorySizeMB'} * 1024 * 1024;
        $data->{$entity_value}->{'mem.consumed.average'} = $mem_consumed;
        $data->{$entity_value}->{'mem.active.average'} = $mem_active;
        $data->{$entity_value}->{'mem.overhead.average'} = $mem_overhead;
        $data->{$entity_value}->{'mem.vmmemctl.average'} = $mem_ballooning;
        $data->{$entity_value}->{'mem.shared.average'} = $mem_shared;
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
