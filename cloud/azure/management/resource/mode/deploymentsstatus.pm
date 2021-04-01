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

package cloud::azure::management::resource::mode::deploymentsstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Status '%s' [Duration: %s] [Last modified: %s]", $self->{result_values}->{status},
        $self->{result_values}->{duration},
        $self->{result_values}->{last_modified});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{duration} = centreon::plugins::misc::change_seconds(value => $options{new_datas}->{$self->{instance} . '_duration'});
    $self->{result_values}->{last_modified} = $options{new_datas}->{$self->{instance} . '_last_modified'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Deployments ";
}

sub prefix_deployment_output {
    my ($self, %options) = @_;
    
    return "Deployment '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'deployments', type => 1, cb_prefix_output => 'prefix_deployment_output', message_multiple => 'All deployments are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-succeeded', set => {
                key_values => [ { name => 'succeeded' }  ],
                output_template => "succeeded : %s",
                perfdatas => [
                    { label => 'total_succeeded', value => 'succeeded', template => '%d', min => 0 },
                ],
            }
        },
        { label => 'total-failed', set => {
                key_values => [ { name => 'failed' }  ],
                output_template => "failed : %s",
                perfdatas => [
                    { label => 'total_failed', value => 'failed', template => '%d', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{deployments} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'duration' }, { name => 'last_modified' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
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
    
    $options{options}->add_options(arguments =>
                                {
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "filter-counters:s"     => { name => 'filter_counters' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{status} ne "Succeeded"' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --resource-group option");
        $self->{output}->option_exit();
    }

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        succeeded => 0, failed => 0,
    };
    $self->{deployments} = {};
    my $deployments = $options{custom}->azure_list_deployments(resource_group => $self->{option_results}->{resource_group});
    foreach my $deployment (@{$deployments}) {
        my $duration = $options{custom}->convert_duration(time_string => $deployment->{properties}->{duration});
        
        $self->{deployments}->{$deployment->{id}} = { 
            display => $deployment->{name}, 
            status => $deployment->{properties}->{provisioningState},
            duration => $duration,
            last_modified => ($deployment->{properties}->{timestamp} =~ /^(.*)\..*$/) ? $1 : '',
        };

        foreach my $status (keys %{$self->{global}}) {
            $self->{global}->{$status}++ if ($deployment->{properties}->{provisioningState} =~ /$status/i);
        }
    }
    
    if (scalar(keys %{$self->{deployments}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No deployments found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check deployments status.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::management::resource::plugin --custommode=azcli --mode=deployments-status
--filter-counters='^total-failed$' --critical-total-failed='1' --verbose

=over 8

=item B<--resource-group>

Set resource group (Required).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-succeeded$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} ne "Succeeded"').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-succeeded', 'total-failed'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-succeeded', 'total-failed'.

=back

=cut
