#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package cloud::azure::database::sqldatabase::mode::memory;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'sqlserver_process_memory_percent' => {
            'output' => 'Memory used percent',
            'label'  => 'usage-percent',
            'nlabel' => 'sqldatabase.memory.usage.percentage',
            'unit'   => '%',
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
        'resource-group:s' => { name => 'resource_group' },
        'server:s'         => { name => 'server' }
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource}) || $self->{option_results}->{resource} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify either --resource <name> with --resource-group and --server option OR --resource <id>.');
        $self->{output}->option_exit();
    }
    my $resource = $self->{option_results}->{resource};
    my $server = $self->{option_results}->{server};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Sql\/servers\/(.*)\/databases\/(.*)$/) {
        $resource_group = $1;
        $server = $2;
        $resource = $2 . '/databases/' . $3;
    } else {
        $resource = $server . '/databases/' . $resource;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'servers';
    $self->{az_resource_namespace} = 'Microsoft.Sql';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT5M';
    $self->{az_aggregations} = ['Maximum'];
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

Check Azure SQL Database Memory.
Metrics are available with:
- Tier 'DTU based' - Basic, Standard, Premium
- vCore based model - General purpose & Business critical
- HyperScale

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::database::sqldatabase::plugin --mode=memory --custommode=api
--resource=<database_name> --resource-group=<resourcegroup_id> --server=<server_name> --aggregation='maximum'
--warning-usage-percent='80'' --critical-usage-percent='90'

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::database::sqldatabase::plugin --mode=memory --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.Sql/servers/<server_name>/databases/<database_name>'
--aggregation='maximum' --warning-usage-percent='80'' --critical-usage-percent='90'

Default aggregation: 'maximum', other are not identified as relevant nor available by Microsoft. 

=over 8

=item B<--resource>

Set resource name or id (Required). It is the database name. 

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--server>

Set server name (Required if resource's name is used).

=item B<--warning-*> B<--critical-*>

Thresholds where '*' can be: 'usage-percent'.

=back

=cut