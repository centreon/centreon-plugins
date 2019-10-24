#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::azure::management::monitor::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{summary} = $options{new_datas}->{$self->{instance} . '_summary'};
    return 0;
}

sub custom_output {
    my ($self, %options) = @_;
    
    return sprintf("Status: '%s', Summary: '%s'",
        $self->{result_values}->{status},
        $self->{result_values}->{summary}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'health', type => 0 },
    ];

    $self->{maps_counters}->{health} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'summary' } ],
                closure_custom_calc => $self->can('custom_calc'),
                closure_custom_output => $self->can('custom_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "resource:s"        => { name => 'resource' },
        "resource-group:s"  => { name => 'resource_group' },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '%{status} =~ /^Unavailable$/' },
        "unknown-status:s"  => { name => 'unknown_status', default => '' },
        "ok-status:s"       => { name => 'ok_status', default => '%{status} =~ /^Available$/' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{api_version} = '2017-07-01';

    if (!defined($self->{option_results}->{resource})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify either --resource <name> with --resource-group option or --resource <id>.");
        $self->{output}->option_exit();
    }
    
    $self->{az_resource} = $self->{option_results}->{resource};
    $self->{az_resource_group} = $self->{option_results}->{resource_group} if (defined($self->{option_results}->{resource_group}));

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status', 'ok_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $resource_group = $self->{az_resource_group};
    my $resource_name = $self->{az_resource};
    if ($self->{az_resource} =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Compute\/virtualMachines\/(.*)$/i) {
        $resource_group = $1;
        $resource_name = $2;
    }

    my $status = $options{custom}->azure_get_resource_health(
        resource => $resource_name,
        resource_group => $resource_group,
        resource_type => $self->{type},
        resource_namespace => $self->{namespace}
    );

    $self->{health} = {
        status => $status->{properties}->{availabilityState},
        summary => $status->{properties}->{summary}
    };
}

1;

__END__

=head1 MODE

Check virtual machine resources CPU metrics.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::compute::virtualmachine::plugin --custommode=azcli --mode=cpu
--resource=MYSQLINSTANCE --resource-group=MYHOSTGROUP --filter-metric='Credits' --aggregation='average'
--critical-cpu-credits-remaining-average='10' --verbose

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::compute::virtualmachine::plugin --custommode=azcli --mode=cpu
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/virtualMachines/xxx'
--filter-metric='Credits' --aggregation='average' --critical-cpu-credits-remaining-average='10' --verbose

Default aggregation: 'average' / All aggregations are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--filter-metric>

Filter metrics (Can be: 'CPU Credits Remaining', 'CPU Credits Consumed',
'Percentage CPU') (Can be a regexp).

=item B<--warning-$metric$-$aggregation$>

Thresholds warning ($metric$ can be: 'cpu-credits-remaining', 'cpu-credits-consumed', 
'percentage-cpu', $aggregation$ can be: 'minimum', 'maximum', 'average', 'total').

=item B<--critical-$metric$-$aggregation$>

Thresholds critical ($metric$ can be: 'cpu-credits-remaining', 'cpu-credits-consumed', 
'percentage-cpu', $aggregation$ can be: 'minimum', 'maximum', 'average', 'total').

=back

=cut
