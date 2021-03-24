#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package cloud::azure::common::appservice::mode::httprequests;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'requests' => {
            'output' => 'Requests',
            'label'  => 'requests',
            'nlabel' => 'appservice.http.request.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'requestsinapplicationqueue' => {
            'output' => 'Requests In Application Queue',
            'label'  => 'requests-queue',
            'nlabel' => 'appservice.http.request.queue.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http101' => {
            'output' => 'Http 101',
            'label'  => 'http-101',
            'nlabel' => 'appservice.htpp.request.101.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http2xx' => {
            'output' => 'Http 2xx',
            'label'  => 'http-2xx',
            'nlabel' => 'appservice.htpp.request.2xx.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http3xx' => {
            'output' => 'Http 3xx',
            'label'  => 'http-3xx',
            'nlabel' => 'appservice.htpp.request.3xx.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http4xx' => {
            'output' => 'Http 4xx',
            'label'  => 'http-4xx',
            'nlabel' => 'appservice.htpp.request.4xx.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http401' => {
            'output' => 'Http 401',
            'label'  => 'http-401',
            'nlabel' => 'appservice.htpp.request.401.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http403' => {
            'output' => 'Http 403',
            'label'  => 'http-403',
            'nlabel' => 'appservice.htpp.request.403.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http404' => {
            'output' => 'Http 404',
            'label'  => 'http-404',
            'nlabel' => 'appservice.htpp.request.404.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http406' => {
            'output' => 'Http 406',
            'label'  => 'http-406',
            'nlabel' => 'appservice.htpp.request.406.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'http5xx' => {
            'output' => 'Http 5xx',
            'label'  => 'http-5xx',
            'nlabel' => 'appservice.htpp.request.5xx.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        }
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-metric:s'  => { name => 'filter_metric' },
        'resource:s'       => { name => 'resource' },
        'resource-group:s' => { name => 'resource_group' }
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --resource <name> with --resource-group option or --resource <id>.');
        $self->{output}->option_exit();
    }
    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Web\/sites\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'sites';
    $self->{az_resource_namespace} = 'Microsoft.Web';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Total'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Azure App Service HTTP requests count.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::common::appservice::plugin --mode=http-requests --custommode=api
--resource=<sites_id> --resource-group=<resourcegroup_id> --aggregation='total'
--warning-requests='80' --critical-requests='90'

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::common::appservice::plugin --mode=http-requests --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.Web/sites/<sites_id>'
--aggregation='total' --warning-requests='80' --critical-requests='90'

Default aggregation: 'total' / 'minimum', 'maximum' and 'average' are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--warning-*>

Warning threshold where '*' can be:
'requests', 'requests-queue', 'http-101', 'http-2xx', 'http-3xx', 'http-4xx', 
'http-401','http-403', 'http-404', 'http-406', 'http-5xx'.

=item B<--critical-*>

Critical threshold  where '*' can be:.
'requests', 'requests-queue', 'http-101', 'http-2xx', 'http-3xx', 'http-4xx', 
'http-401','http-403', 'http-404', 'http-406', 'http-5xx'.

=back

=cut
