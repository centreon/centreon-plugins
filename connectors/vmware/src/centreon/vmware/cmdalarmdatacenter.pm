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

package centreon::vmware::cmdalarmdatacenter;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'alarmdatacenter';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{datacenter}) && $options{arguments}->{datacenter} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: datacenter cannot be null");
        return 1;
    }
    return 0;
}

sub run {
    my $self = shift;
    
    my $filters = $self->build_filter(label => 'name', search_option => 'datacenter', is_regexp => 'filter');   
    my @properties = ('name', 'triggeredAlarmState');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'Datacenter', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    my $data = {};
    foreach my $datacenter_view (@$result) {
        $data->{$datacenter_view->{mo_ref}->{value}} = { name => $datacenter_view->name, red => 0, yellow => 0, alarms => {} };
        next if (!defined($datacenter_view->triggeredAlarmState));
        foreach (@{$datacenter_view->triggeredAlarmState}) {
            next if ($_->overallStatus->val !~ /(red|yellow)/i);

            my $entity = centreon::vmware::common::get_view($self->{connector}, $_->entity, ['name']);
            my $alarm = centreon::vmware::common::get_view($self->{connector}, $_->alarm, ['info']);
            
            $data->{$datacenter_view->{mo_ref}->{value}}->{alarms}->{$_->key} = { type => $_->entity->type, entity_name => $entity->name, 
                time => $_->time, name => $alarm->info->name, 
                description => $alarm->info->description, 
                status => $_->overallStatus->val
            };
            $data->{$datacenter_view->{mo_ref}->{value}}->{$_->overallStatus->val}++;
        }
    }    

    centreon::vmware::common::set_response(data => $data);
}

1;
