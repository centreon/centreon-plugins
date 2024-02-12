#
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
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package cloud::azure::compute::virtualmachine::mode::cpu;

use base qw(cloud::azure::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'CPU Credits Consumed' => {
            'output' => 'Credits consumed',
            'label'  => 'cpu-credits-consumed',
            'nlabel' => 'azvm.cpu.credits.consumed.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'CPU Credits Remaining' => {
            'output' => 'Credits remaining',
            'label'  => 'cpu-credits-remaining',
            'nlabel' => 'azvm.cpu.credits.remaining.count',
            'unit'   => '',
            'min'    => '0',
            'max'    => ''
        },
        'Percentage CPU' => {
            'output' => 'Percentage',
            'label'  => 'cpu-utilization',
            'nlabel' => 'azvm.cpu.utilization.percentage',
            'unit'   => '%',
            'min'    => '0',
            'max'    => '100'
        }
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'api-version:s'    => { name => 'api_version', default => '2018-01-01'},
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

    $self->{api_version} = (defined($self->{option_results}->{api_version}) && $self->{option_results}->{api_version} ne "") ? $self->{option_results}->{api_version} : "2018-01-01";

    my $resource = $self->{option_results}->{resource};
    my $resource_group = defined($self->{option_results}->{resource_group}) ? $self->{option_results}->{resource_group} : '';

    if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Compute\/virtualMachines\/(.*)$/) {
        $resource_group = $1;
        $resource = $2;
    }

    $self->{az_resource} = $resource;
    $self->{az_resource_group} = $resource_group;
    $self->{az_resource_type} = 'virtualMachines';
    $self->{az_resource_namespace} = 'Microsoft.Compute';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT5M";
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

Check virtual machine resources CPU metrics.

Example:

Using resource name:

perl centreon_plugins.pl --plugin=cloud::azure::compute::virtualmachine::plugin 
--custommode=azcli --mode=cpu --resource=MYVMINSTANCE --resource-group=MYRSCGROUP 
--filter-metric='Credits' --critical-cpu-credits-remaining='10:' --verbose

Using resource ID:

perl centreon_plugins.pl --plugin=cloud::azure::compute::virtualmachine::plugin 
--custommode=azcli --mode=cpu --resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/virtualMachines/xxx'
--filter-metric='Credits' --critical-cpu-credits-remaining='10:' --verbose

Default aggregation: 'average'

=over 8

=item B<--resource>

Set resource name or ID (required).

=item B<--resource-group>

Set resource group (required if resource's name is used).

=item B<--filter-metric>

Filter metrics (can be: 'CPU Credits Remaining', 'CPU Credits Consumed',
'Percentage CPU') (can be a regexp).

=item B<--warning-$label$>

Warning threshold
($label$ can be: 'cpu-credits-remaining', 'cpu-credits-consumed', 'cpu-utilization')

=item B<--critical-$label$>

Critical threshold
($label$ can be: 'cpu-credits-remaining', 'cpu-credits-consumed', 'cpu-utilization')

=back

=cut