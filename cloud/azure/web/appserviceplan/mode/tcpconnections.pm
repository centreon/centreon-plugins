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

package cloud::azure::web::appserviceplan::mode::tcpconnections;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'tcpclosewait' => {
            'output'   => 'TCP Close Wait',
            'label'    => 'tcp-closewait',
            'nlabel'   => 'appserviceplan.connections.tcp.closewait.count',
            'unit'     => '',
            'min'      => '0',
            'template' => '%d'
        },
        'tcpclosing' => {
            'output'   => 'TCP Closing',
            'label'    => 'tcp-closing',
            'nlabel'   => 'appserviceplan.connections.tcp.closing.count',
            'unit'     => '',
            'min'      => '0',
            'template' => '%d'
        },
        'tcpfinwait1' => {
            'output'   => 'TCP Fin Wait 1',
            'label'    => 'tcp-fin-wait1',
            'nlabel'   => 'appserviceplan.connections.tcp.finwait1.count',
            'unit'     => '',
            'min'      => '0',
            'template' => '%d'
        },
        'tcpfinwait2' => {
            'output'   => 'TCP Fin Wait 2',
            'label'    => 'tcp-fin-wait2',
            'nlabel'   => 'appserviceplan.connections.tcp.finwait2.count',
            'unit'     => '',
            'min'      => '0',
            'template' => '%d'
        },
        'tcplastack' => {
            'output'   => 'TCP Last Ack',
            'label'    => 'tcp-ack-last',
            'nlabel'   => 'appserviceplan.connections.tcp.lastack.count',
            'unit'     => '',
            'min'      => '0',
            'template' => '%d'
        },
        'tcpsynreceived' => {
            'output'   => 'TCP Syn Received',
            'label'    => 'tcp-syn-received',
            'nlabel'   => 'appserviceplan.connections.tcp.synreceived.count',
            'unit'     => '',
            'min'      => '0',
            'template' => '%d'
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
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Web\/serverFarms\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'serverFarms';
    $self->{az_resource_namespace} = 'Microsoft.Web';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Average'];
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

Check Azure App Service Plan TCP connections statistics.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::web::appserviceplan::plugin --mode=tcp-connections --custommode=api
--resource=<appsvcplan_id> --resource-group=<resourcegroup_id> --aggregation='average'
--warning-tcp-closewait='1000' --critical-tcp-closewait='2000'

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::web::appserviceplan::plugin --mode=tcp-connections --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.Web/serverFarms/<appsvcplan_id>'
--aggregation='average' --warning-tcp-closewait='1000' --critical-tcp-closewait='2000'

Default aggregation: 'average' / 'total', 'minimum' and 'maximum' are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--warning-*>

Warning threshold where '*' can be:
'tcp-syn-received', 'tcp-ack-last', 'tcp-fin-wait2', 'tcp-fin-wait1',
'tcp-closewait', 'tcp-closing'.

=item B<--critical-*>

Critical threshold where '*' can be:
'tcp-syn-received', 'tcp-ack-last', 'tcp-fin-wait2', 'tcp-fin-wait1',
'tcp-closewait', 'tcp-closing'.

=back

=cut
