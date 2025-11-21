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

package centreon::vmware::cmdstatuscluster;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'statuscluster';
    
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

    my $vsan_cluster_health;
    my $filters = $self->build_filter(label => 'name', search_option => 'cluster_name', is_regexp => 'filter');
    my @properties = ('name', 'summary.overallStatus', 'configuration');
    if ($self->is_vsan_enabled()) {
        $vsan_cluster_health = centreon::vmware::common::vsan_create_mo_view(
            vsan_vim => $self->{connector}->{vsan_vim},
            type => 'VsanVcClusterHealthSystem',
            value => 'vsan-cluster-health-system',
        );
        push @properties, 'configurationEx';
    }
    my $views = centreon::vmware::common::search_entities(command => $self, view_type => 'ClusterComputeResource', properties => \@properties, filter => $filters);
    return if (!defined($views));

    my $data = {};
    foreach my $view (@$views) {
        my $entity_value = $view->{mo_ref}->{value};
        $data->{$entity_value} = {
            name => $view->{name},
            overall_status => $view->{'summary.overallStatus'}->val,
            ha_enabled => (defined($view->{configuration}->{dasConfig}->{enabled}) && $view->{configuration}->{dasConfig}->{enabled} =~ /^1|true/i) ? 'true' : 'false',
            drs_enabled => (defined($view->{configuration}->{drsConfig}->{enabled}) && $view->{configuration}->{drsConfig}->{enabled} =~ /^1|true/i) ? 'true' : 'false'
        };

        if (defined($view->{configurationEx}->{vsanConfigInfo}) && $view->{configurationEx}->{vsanConfigInfo}->enabled == 1) {
             my $summary = $vsan_cluster_health->VsanQueryVcClusterHealthSummary(
                cluster => $view,
                includeObjUuids => 'false',
                fetchFromCache =>  'false',
                fields => ['clusterStatus']
            );
            $data->{$entity_value}->{vsan_cluster_status} = $summary->clusterStatus->status;
        }
    }

    centreon::vmware::common::set_response(data => $data);
}

1;
