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

package cloud::azure::devtools::appconfiguration::mode::httprequests;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'httpincomingrequestcount' => {
            'output' => 'Incoming HTTP requests',
            'label'  => 'http-requests',
            'nlabel' => 'appconfiguration.http.incoming.requests.count',
            'unit'   => '',
            'min'    => '0'
        },
        'httpincomingrequestduration' => {
            'output' => 'Incoming HTTP requests duration',
            'label'  => 'http-requests-duration',
            'nlabel' => 'appconfiguration.http.incoming.requests.milliseconds',
            'unit'   => 'ms',
            'min'    => '0'
        },
        'throttledhttprequestcount' => {
            'output' => 'Throttled Incoming HTTP requests',
            'label'  => 'http-throttled-requests',
            'nlabel' => 'appconfiguration.http.throttled.incoming.requests.count',
            'unit'   => '',
            'min'    => '0'
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
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.AppConfiguration\/configurationStores\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'configurationStores';
    $self->{az_resource_namespace} = 'Microsoft.AppConfiguration';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Count'];
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

Check Azure App Configuration HTTP requests.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::devtools::appconfiguration::plugin --mode=http-requests --custommode=api
--resource=<busnamespace_id> --resource-group=<resourcegroup_id> --aggregation='count' 
--warning-http-requests='1000' --critical-http-requests='2000'

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::devtools::appconfiguration::plugin --mode=http-requests --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.AppConfiguration/configurationStores/<configurationstores_id>'
--aggregation='count' --warning-http-requests='1000' --critical-http-requests='2000'

Default aggregation: 'count' / 'total', 'average', 'minimum' and 'maximum' are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--warning-*>

Warning threshold where '*' can be:
'http-requests', 'http-requests-duration', 'http-throttled-requests'.

=item B<--critical-*>

Critical threshold where '*' can be:
'http-requests', 'http-requests-duration', 'http-throttled-requests'.

=back

=cut