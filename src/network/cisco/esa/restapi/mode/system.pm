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

package network::cisco::esa::restapi::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub system_long_output {
    my ($self, %options) = @_;

    return 'checking system';
}

sub prefix_message_output {
    my ($self, %options) = @_;

    return 'messages in ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 3, cb_long_output => 'system_long_output', indent_long_output => '    ',
            group => [
                { name => 'cpu', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'rc', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'message', type => 0, cb_prefix_output => 'prefix_message_output', display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'queue', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-utilization', nlabel => 'system.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_util' } ],
                output_template => 'cpu utilization: %.2f%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory', nlabel => 'system.memory.usage.percentage', set => {
                key_values => [ { name => 'ram_utilization' } ],
                output_template => 'memory usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'swap', nlabel => 'system.swap.usage.percentage', set => {
                key_values => [ { name => 'swap_utilization' } ],
                output_template => 'swap usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{rc} = [
        { label => 'resource-conservation', nlabel => 'system.resource.conservation.current.count', set => {
                key_values => [ { name => 'resource_conservation' } ],
                output_template => 'current resource conservation: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{message} = [
         { label => 'messages-quarantine', nlabel => 'system.queue.messages.quarantine.current.count', set => {
                key_values => [ { name => 'quarantine' } ],
                output_template => 'quarantine: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'messages-workqueue', nlabel => 'system.queue.messages.workqueue.current.count', set => {
                key_values => [ { name => 'workqueue' } ],
                output_template => 'workqueue: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{queue} = [
        { label => 'queue-utilization', nlabel => 'system.queue.utilization.percentage', set => {
                key_values => [ { name => 'queue_util' } ],
                output_template => 'queue utilization: %.2f%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%' }
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $infos = $options{custom}->request_api(endpoint => '/esa/api/v2.0/health');

    $self->{output}->output_add(short_msg => 'System is ok');

    $self->{system} = {
        global => {
            cpu => {
                cpu_util => $infos->{data}->{percentage_cpu_load}
            },
            memory => {
                ram_utilization => $infos->{data}->{percentage_ram_utilization},
                swap_utilization => $infos->{data}->{percentage_swap_utilization}
            },
            rc => { resource_conservation => $infos->{data}->{resource_conservation} },
            message => {
                quarantine => $infos->{data}->{messages_in_pvo_quarantines},
                workqueue => $infos->{data}->{messages_in_workqueue}
            },
            queue => {
                queue_util => $infos->{data}->{percentage_queue_utilization}
            }
        }
    };
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='memory'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'resource-conservation', 'cpu-utilization' (%),
'messages-quarantine', 'messages-workqueue',
'queue-utilization' (%), 'memory' (%), 'swap' (%).

=back

=cut
