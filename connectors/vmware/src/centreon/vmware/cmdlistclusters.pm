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

package centreon::vmware::cmdlistclusters;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'listclusters';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{cluster}) && $options{arguments}->{cluster} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: cluster cannot be null");
        return 1;
    }
    return 0;
}

sub run {
    my $self = shift;

    my $filters = $self->build_filter(label => 'name', search_option => 'cluster', is_regexp => 'filter');
    my @properties = ('name');

    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'ClusterComputeResource', properties => \@properties, filter => $filters);
    return if (!defined($result));

    my $data = {};
    foreach my $cluster (@$result) {
        $data->{$cluster->{mo_ref}->{value}} = { name => $cluster->name };
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
