#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::latencetech::restapi::mode::forecast;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return "Agent '" . $options{instance_value}->{display} . "' ";
}

sub custom_forecast_output {
    my ($self, %options) = @_;

    return sprintf('Projected latency %.2fms (forecasting interval: %.2fms, confidence level: %s)', 
        $self->{result_values}->{projectedLatencyMs}, $self->{result_values}->{forecastingIntervalMs}, $self->{result_values}->{confidenceLevel});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'projected-latency', nlabel => 'latency.projected.time.milliseconds', set => {
                key_values => [ { name => 'projectedLatencyMs' }, { name => 'display' }, { name => 'confidenceLevel' }, { name => 'forecastingIntervalMs' }],
                closure_custom_output => $self->can('custom_forecast_output'),
                perfdatas => [
                    { value => 'projectedLatencyMs', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    my $results = $options{custom}->request_api(endpoint => '/forecast');
    $self->{global}->{display} = $results->{agentID};
    foreach my $kpi (keys %{$results}) {
        $self->{global}->{$kpi} = $results->{$kpi};        
    }
}

1;

__END__

=head1 MODE

Check agent forecast statistics.

=over 8

=item B<--agent-id>

Set the ID of the agent (mandatory option).

=item B<--warning-projected-latency>

Warning thresholds for projected latency.

=item B<--critical-projected-latency>

Critical thresholds for projected latency.

=back

=cut
