#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::vcs::restapi::mode::calls;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s' [Duration: %s s]",
        $self->{result_values}->{state}, $self->{result_values}->{duration});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{serial_number} = $options{new_datas}->{$self->{instance} . '_SerialNumber'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_State'};
    $self->{result_values}->{duration} = $options{new_datas}->{$self->{instance} . '_Duration'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'calls', type => 1, cb_prefix_output => 'prefix_call_output', message_multiple => 'All calls are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'traversal', set => {
                key_values => [ { name => 'Traversal' } ],
                output_template => 'Traversal: %d',
                perfdatas => [
                    { label => 'traversal', value => 'Traversal', template => '%d',
                      min => 0, unit => 'calls' },
                ],
            }
        },
        { label => 'non-traversal', set => {
                key_values => [ { name => 'NonTraversal' } ],
                output_template => 'Non Traversal: %d',
                perfdatas => [
                    { label => 'non_traversal', value => 'NonTraversal', template => '%d',
                      min => 0, unit => 'calls' },
                ],
            }
        },
        { label => 'collaboration-edge', set => {
                key_values => [ { name => 'CollaborationEdge' } ],
                output_template => 'Collaboration Edge: %d',
                perfdatas => [
                    { label => 'collaboration_edge', value => 'CollaborationEdge', template => '%d',
                      min => 0, unit => 'calls' },
                ],
            }
        },
        { label => 'cloud', set => {
                key_values => [ { name => 'Cloud' } ],
                output_template => 'Cloud: %d',
                perfdatas => [
                    { label => 'cloud', value => 'Cloud', template => '%d',
                      min => 0, unit => 'calls' },
                ],
            }
        },
        { label => 'microsoft-content', set => {
                key_values => [ { name => 'MicrosoftContent' } ],
                output_template => 'Microsoft Content: %d',
                perfdatas => [
                    { label => 'microsoft_content', value => 'MicrosoftContent', template => '%d',
                      min => 0, unit => 'calls' },
                ],
            }
        },
        { label => 'microsoft-imp', set => {
                key_values => [ { name => 'MicrosoftIMP' } ],
                output_template => 'Microsoft IMP: %d',
                perfdatas => [
                    { label => 'microsoft_imp', value => 'MicrosoftIMP', template => '%d',
                      min => 0, unit => 'calls' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{calls} = [
        { label => 'status', set => {
                key_values => [ { name => 'State' }, { name => 'Duration' }, { name => 'SerialNumber' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Number of Calls ";
}

sub prefix_call_output {
    my ($self, %options) = @_;

    return "Call '" . $options{instance_value}->{SerialNumber} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "warning-status:s"      => { name => 'warning_status' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{state} ne "Connected"' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $usages = $options{custom}->get_endpoint(method => '/Status/ResourceUsage/Calls');

    $self->{global}->{Traversal} = $usages->{ResourceUsage}->{Calls}->{Traversal}->{Current}->{content};
    $self->{global}->{NonTraversal} = $usages->{ResourceUsage}->{Calls}->{NonTraversal}->{Current}->{content};
    $self->{global}->{CollaborationEdge} = $usages->{ResourceUsage}->{Calls}->{CollaborationEdge}->{Current}->{content};
    $self->{global}->{Cloud} = $usages->{ResourceUsage}->{Calls}->{Cloud}->{Current}->{content};
    $self->{global}->{MicrosoftContent} = $usages->{ResourceUsage}->{Calls}->{MicrosoftContent}->{Current}->{content};
    $self->{global}->{MicrosoftIMP} = $usages->{ResourceUsage}->{Calls}->{MicrosoftIMP}->{Current}->{content};

    my $results = $options{custom}->get_endpoint(method => '/Status/Calls');

    $self->{calls} = {};

    foreach my $call (@{$results->{Calls}->{Call}}) {
        next if (!defined($call->{SerialNumber}));
        $self->{calls}->{$call->{SerialNumber}->{content}} = {
            SerialNumber => $call->{SerialNumber}->{content},
            Duration => $call->{Duration}->{content},
            State => $call->{State}->{content},
        };
    }
}

1;

__END__

=head1 MODE

Check calls count and state.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'traversal', 'non-traversal', 'collaboration-edge',
'cloud', 'microsoft-content', 'microsoft-imp'.

=item B<--critical-*>

Threshold critical.
Can be: 'traversal', 'non-traversal', 'collaboration-edge',
'cloud', 'microsoft-content', 'microsoft-imp'.

=item B<--warning-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{state}, %{serial_number}, %{duration}.

=item B<--critical-status>

Set critical threshold for status. (Default: '%{state} ne "Connected"').
Can use special variables like: %{state}, %{serial_number}, %{duration}.

=back

=cut
