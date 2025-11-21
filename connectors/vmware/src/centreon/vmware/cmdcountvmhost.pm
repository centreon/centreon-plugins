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

package centreon::vmware::cmdcountvmhost;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'countvmhost';
    
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

    my $filters = $self->build_filter(label => 'name', search_option => 'esx_hostname', is_regexp => 'filter');
    my @properties = ('name', 'vm', 'runtime.connectionState');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => $filters);
    return if (!defined($result));

    #return if (centreon::vmware::common::host_state($self->{connector}, $self->{lhost}, 
    #                                              $$result[0]->{'runtime.connectionState'}->val) == 0);

    my @vm_array = ();
    foreach my $entity_view (@$result) {
        if (defined($entity_view->vm)) {
            @vm_array = (@vm_array, @{$entity_view->vm});
        }
    }
    @properties = ('runtime.powerState');
    my $result2 = centreon::vmware::common::get_views($self->{connector}, \@vm_array, \@properties);
    return if (!defined($result2));

    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        $data->{$entity_value} = { name => $entity_view->{name}, state => $entity_view->{'runtime.connectionState'}->val };        
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);
        
        my %vm_states = (poweredon => 0, poweredoff => 0, suspended => 0);
        if (defined($entity_view->vm)) {
            foreach my $vm_host (@{$entity_view->vm}) {
                foreach my $vm (@{$result2}) {
                    if ($vm_host->{value} eq $vm->{mo_ref}->{value}) {
                        my $power_value = lc($vm->{'runtime.powerState'}->val);
                        $vm_states{$power_value}++;
                        last;
                    }
                }
            }
        }
        
        $data->{$entity_value} = { %{$data->{$entity_value}}, %vm_states };
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
