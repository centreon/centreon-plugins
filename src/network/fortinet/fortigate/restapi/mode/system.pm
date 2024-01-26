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

package network::fortinet::fortigate::restapi::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub vdom_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking vdom '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_vdom_output {
    my ($self, %options) = @_;

    return sprintf(
        "vdom '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vdoms', type => 3, cb_prefix_output => 'prefix_vdom_output', cb_long_output => 'vdom_long_output', indent_long_output => '    ', message_multiple => 'All vdom systems are ok',
            group => [
                { name => 'cpu', type => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, skipped_code => { -10 => 1 } },
                { name => 'session', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-utilization', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'load' } ],
                output_template => 'cpu load: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'memory used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{session} = [
        { label => 'sessions-active', nlabel => 'sessions.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-vdom:s' => { name => 'filter_vdom' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $resources = $options{custom}->request_api(
        endpoint => '/api/v2/monitor/system/vdom-resource/select/',
        get_param => ['global=1']
    );

    if (ref($resources) ne 'ARRAY') {
        $resources = [$resources];
    }

    $self->{vdoms} = {};
    foreach my $resource (@$resources) {
        next if (defined($self->{option_results}->{filter_vdom}) && $self->{option_results}->{filter_vdom} ne '' &&
            $resource->{vdom} !~ /$self->{option_results}->{filter_vdom}/);

        $self->{vdoms}->{ $resource->{vdom} } = {
            name => $resource->{vdom},
            cpu => { load => $resource->{results}->{cpu} },
            memory => { used => $resource->{results}->{memory} },
            session => { active => $resource->{results}->{session}->{current_usage} }
        };
    }
}

1;

__END__

=head1 MODE

Check vdom system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='memory-usage'

=item B<--filter-vdom>

Filter vdom by name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization' (%), 'memory-usage' (%), 'sessions-active'.

=back

=cut
