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

package centreon::vmware::cmdvsanclusterusage;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'vsanclusterusage';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{cluster_name}) && $options{arguments}->{cluster_name} eq '') {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: cluster name cannot be null");
        return 1;
    }

    return 0;
}

sub run {
    my $self = shift;

    if (!$self->is_vsan_enabled()) {
        centreon::vmware::common::set_response(code => 100, short_message => 'Vsan is not enabled in vmware connector');
        return ;
    }

    my $filters = $self->build_filter(label => 'name', search_option => 'cluster_name', is_regexp => 'filter');
    my @properties = ('name', 'configurationEx');
    my $views = centreon::vmware::common::search_entities(command => $self, view_type => 'ComputeResource', properties => \@properties, filter => $filters);
    return if (!defined($views));

    my $vsan_performance_mgr = centreon::vmware::common::vsan_create_mo_view(
        vsan_vim => $self->{connector}->{vsan_vim},
        type => 'VsanPerformanceManager',
        value => 'vsan-performance-manager',
    );

    my $interval_sec = $self->{connector}->{perfcounter_speriod};
    if (defined($self->{sampling_period}) && $self->{sampling_period} ne '') {
        $interval_sec = $self->{sampling_period};
    }

    my $data = {};
    foreach my $view (@$views) {
        next if (!defined($view->{configurationEx}->{vsanConfigInfo}) || $view->{configurationEx}->{vsanConfigInfo}->enabled != 1);

        my $entity_value = $view->{mo_ref}->{value};
        my $uuid = $view->{configurationEx}->{vsanConfigInfo}->{defaultConfig}->{uuid};
        my $result = centreon::vmware::common::vsan_get_performances(
            vsan_performance_mgr => $vsan_performance_mgr,
            cluster => $view,
            entityRefId => 'cluster-domcompmgr:*',
            labels => [
                'iopsRead', 
                'iopsWrite',
                'congestion', # number
                'latencyAvgRead', # time_ms
                'latencyAvgWrite', # time_ms
                'oio', #  outstanding IO (number),
                'throughputRead', # rate_bytes
                'throughputWrite', #  rate_bytes
            ],
            interval => $interval_sec,
            time_shift => $self->{time_shift}
        );
        $data->{$entity_value} = {
            name => $view->{name},
            cluster_domcompmgr => {
                %{$result->{'cluster-domcompmgr:' . $uuid}}
            },
        };
    }

    centreon::vmware::common::set_response(data => $data);
}

1;
