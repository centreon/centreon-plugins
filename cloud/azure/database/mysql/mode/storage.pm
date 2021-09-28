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

package cloud::azure::database::mysql::mode::storage;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'backup_storage_used' => {
            'output' => 'Backup Storage used',
            'label'  => 'storage-backup',
            'nlabel' => 'azmysql.storage.backup.usage.bytes',
            'unit'   => 'B',
            'min'    => '0'
        },
        'serverlog_storage_limit' => {
            'output' => 'Server Log storage limit',
            'label'  => 'serverlog-limit',
            'nlabel' => 'azmysql.storage.serverlog.limit.bytes',
            'unit'   => 'B',
            'min'    => '0'
        },
        'serverlog_storage_percent' => {
            'output' => 'Server Log storage percent',
            'label'  => 'serverlog-percent',
            'nlabel' => 'azmysql.storage.serverlog.usage.percentage',
            'unit'   => '%',
            'min'    => '0'
        },
        'serverlog_storage_usage' => {
            'output' => 'Server Log storage used',
            'label'  => 'servelog-usage',
            'nlabel' => 'azmysql.storage.serverlog.usage.bytes',
            'unit'   => 'B',
            'min'    => '0'
        },
        'storage_limit' => {
            'output' => 'Storage Limit',
            'label'  => 'storage-limit',
            'nlabel' => 'azmysql.storage.limit.bytes',
            'unit'   => 'B',
            'min'    => '0'
        },
        'storage_percent' => {
            'output' => 'Storage Percent',
            'label'  => 'storage-percent',
            'nlabel' => 'azmysql.storage.usage.percentage',
            'unit'   => '%',
            'min'    => '0'
        },
        'storage_used' => {
            'output' => 'Storage Used',
            'label'  => 'storage-used',
            'nlabel' => 'azmysql.storage.usage.bytes',
            'unit'   => 'B',
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
        'resource-group:s' => { name => 'resource_group' },
        'resource-type:s'  => { name => 'resource_type' }
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

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --resource-type option');
        $self->{output}->option_exit();
    }

    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';
    my $resource_type = $self->{option_results}->{resource_type};
    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.DBforMySQL\/(.*)\/(.*)$/) {
        $resource_group = $1;
        $resource_type = $2;
        $resource = $3;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = $resource_type;
    $self->{az_resource_namespace} = 'Microsoft.DBforMySQL';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : 'PT15M';
    $self->{az_aggregations} = ['Maximum'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    my $resource_mapping = {
        'servers' => [ 'backup_storage_used', 'serverlog_storage_limit', 'serverlog_storage_percent', 
                       'serverlog_storage_usage', 'storage_limit', 'storage_percent', 'storage_used'
        ],
        'flexibleServers' => [ 'backup_storage_used', 'storage_limit', 'storage_percent', 'storage_used' ]
    };

    my $metrics_mapping_transformed;
    foreach my $metric_type (@{$resource_mapping->{$resource_type}}) {
        $metrics_mapping_transformed->{$metric_type} = $self->{metrics_mapping}->{$metric_type};
    }

    foreach my $metric (keys %{$metrics_mapping_transformed}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{az_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Azure Database for MySQL storage usage.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::database::mysql::plugin --mode=storage --custommode=api
--resource=<db_id> --resource-group=<resourcegroup_id> --aggregation='maximum'
--warning-storage_used='1000' --critical-storage_used='2000'

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::integration::servicebus::plugin --mode=storage --custommode=api
--resource='/subscriptions/<subscription_id>/resourceGroups/<resourcegroup_id>/providers/Microsoft.DBforMySQL/servers/<db_id>'
--aggregation='maximum' --warning-storage_used='1000' --critical-storage_used='2000'

Default aggregation: 'maximum' / 'average', 'minimum' and 'total' are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--resource-type>

Set resource type (Default: 'servers'). Can be 'servers', 'flexibleServers'.

=item B<--warning-*>

Warning threshold where '*' can be:
'storage-backup', 'serverlog-limit', 'serverlog-percent', 'servelog-usage', 
'storage-limit', 'storage-percent', 'storage-used'.

=item B<--critical-*>

Critical threshold where '*' can be:
'storage-backup', 'serverlog-limit', 'serverlog-percent', 'servelog-usage', 
'storage-limit', 'storage-percent', 'storage-used'.

=back

=cut
