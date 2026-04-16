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

package apps::monitoring::latencetech::restapi::mode::twamp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'twamp-forward', nlabel => 'twamp.forwarddelta.time.milliseconds', set => {
                key_values => [ { name => 'TWAMPfwdDelta' }, { name => 'display' } ],
                output_template => 'TWAMP Forward Delta: %.2fms',
                perfdatas => [
                    { value => 'TWAMPfwdDelta', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'twamp-reverse', nlabel => 'twamp.reversedelta.time.milliseconds', set => {
                key_values => [ { name => 'TWAMPRevDelta' }, { name => 'display' } ],
                output_template => 'TWAMP Reverse Delta: %.2fms',
                perfdatas => [
                    { value => 'TWAMPRevDelta', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'twamp-processing', nlabel => 'twamp.processingdelta.time.milliseconds', set => {
                key_values => [ { name => 'TWAMPProcDelta' }, { name => 'display' } ],
                output_template => 'TWAMP Processing Delta: %.2fms',
                perfdatas => [
                    { value => 'TWAMPProcDelta', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Agent '" . $options{instance_value}->{display} . "' ";
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
    my $results = $options{custom}->request_api(endpoint => '/twamp');
    $self->{global}->{display} = $results->{agentID};
    foreach my $kpi (keys %{$results}) {
        $self->{global}->{$kpi} = $results->{$kpi};        
    }
}

1;

__END__

=head1 MODE

Check agent TWAMP statistics.

=over 8

=item B<--agent-id>

Set the ID of the agent (mandatory option).

=item B<--warning-twamp-forward>

Warning thresholds for TWAMP forward delta time (in milliseconds).

=item B<--critical-twamp-forward>

Critical thresholds for TWAMP forward delta time (in milliseconds).

=item B<--warning-twamp-reverse>

Warning thresholds for TWAMP reverse delta time (in milliseconds).

=item B<--critical-twamp-reverse>

Critical thresholds for TWAMP reverse delta time (in milliseconds).

=item B<--warning-twamp-processing>

Warning thresholds for TWAMP processing delta time (in milliseconds).

=item B<--critical-twamp-processing>

Critical thresholds for TWAMP processing delta time (in milliseconds).

=back

=cut
