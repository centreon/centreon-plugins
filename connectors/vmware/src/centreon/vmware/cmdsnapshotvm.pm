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

package centreon::vmware::cmdsnapshotvm;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'snapshotvm';
    
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

    my $filters = $self->build_filter(label => 'name', search_option => 'vm_hostname', is_regexp => 'filter');
    $self->add_filter(filters => $filters, label => 'config.annotation', search_option => 'filter_description');
    $self->add_filter(filters => $filters, label => 'config.guestFullName', search_option => 'filter_os');
    $self->add_filter(filters => $filters, label => 'config.uuid', search_option => 'filter_uuid');
    
    my @properties = ('snapshot.rootSnapshotList', 'name', 'runtime.connectionState', 'runtime.powerState');
    if (defined($self->{check_consolidation}) == 1) {
        push @properties, 'runtime.consolidationNeeded';
    }
    if (defined($self->{display_description})) {
        push @properties, 'config.annotation';
    }

    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'VirtualMachine', properties => \@properties, filter => $filters);
    return if (!defined($result));

    my %vm_consolidate = ();
    my %vm_errors = (warning => {}, critical => {});    
    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};

        $data->{$entity_value} = {
            name => $entity_view->{name},
            connection_state => $entity_view->{'runtime.connectionState'}->val, 
            power_state => $entity_view->{'runtime.powerState'}->val,
            'config.annotation' => defined($entity_view->{'config.annotation'}) ? $entity_view->{'config.annotation'} : undef,
            snapshosts => [],
        };        
        next if (centreon::vmware::common::is_connected(state => $entity_view->{'runtime.connectionState'}->val) == 0);

        if (defined($self->{check_consolidation}) && defined($entity_view->{'runtime.consolidationNeeded'}) && $entity_view->{'runtime.consolidationNeeded'} =~ /^true|1$/i) {
            $data->{$entity_value}->{consolidation_needed} = 1;
        }

        next if (!defined($entity_view->{'snapshot.rootSnapshotList'}));
    
        foreach my $snapshot (@{$entity_view->{'snapshot.rootSnapshotList'}}) {
            # 2012-09-21T14:16:17.540469Z
            push @{$data->{$entity_value}->{snapshosts}}, { name => $snapshot->name, description => $snapshot->description, create_time => $snapshot->createTime };
        }
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
