#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::cadvisor::restapi::mode::nodestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'node', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All node informations are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{nodes} = [
         { label => 'node-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'manager_status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
    $self->{maps_counters}->{node} = [
         { label => 'containers-running', set => {
                key_values => [ { name => 'containers_running' }, { name => 'display' } ],
                output_template => 'Containers Running : %s',
                perfdatas => [
                    { label => 'containers_running', value => 'containers_running', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'num-cores', set => {
                key_values => [ { name => 'num_cores' }, { name => 'display' } ],
                output_template => 'CPU cores: %s',
                perfdatas => [
                    { label => 'num_cores', value => 'num_cores', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'memory-capacity', set => {
                key_values => [ { name => 'memory_capacity' }, { name => 'display' } ],
                output_template => 'Mem capacity %s %s',
                perfdatas => [
                    { label => 'memory_capacity', value => 'memory_capacity', unit => 'B', output_change_bytes => 1, template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'cpu-frequency', set => {
                key_values => [ { name => 'cpu_frequency' }, { name => 'display' } ],
                output_template => 'CPU frequency %s %s',
                perfdatas => [
                    { label => 'cpu_frequency', value => 'cpu_frequency', unit => 'Hz', output_change_bytes => 1, template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
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
                                });
   
    return $self;
}

sub prefix_node_output {
    my ($self, %options) = @_;
    
    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
                  
    $self->{node} = {};
    my $result = $options{custom}->api_list_nodes();
    foreach my $node_name (keys %{$result}) {
        $self->{node}->{$node_name} = {
            display             => $node_name,
            num_cores           => $result->{$node_name}->{num_cores},
            cpu_frequency       => $result->{$node_name}->{cpu_frequency_khz} * 1000,
            memory_capacity     => $result->{$node_name}->{memory_capacity},
            containers_running  => scalar(@{$result->{$node_name}->{nodes}}),
        };
    }
    
    if (scalar(keys %{$self->{node}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No node found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check node status.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'containers-running', 'num-cores', 'memory-capacity', 'cpu-frequency'.

=item B<--critical-*>

Threshold critical.
Can be: 'containers-running', 'num-cores', 'memory-capacity', 'cpu-frequency'.

=back

=cut
