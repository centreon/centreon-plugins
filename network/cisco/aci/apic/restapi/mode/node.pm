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

package network::cisco::aci::apic::restapi::mode::node;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_nodes_output', message_multiple => 'All fabric nodes are ok' }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'health-current', nlabel => 'node.health.current.percentage', set => {
                key_values => [ { name => 'current' }, { name => 'dn' } ],
                output_template => 'current: %s %%', output_error_template => "current: %s %%",
                perfdatas => [
                    { template => '%d', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'dn' }
                ]
            }
        },
        { label => 'health-minimum', nlabel => 'node.health.minimum.percentage', set => {
                key_values => [ { name => 'min' }, { name => 'dn' } ],
                output_template => 'min: %s %%', output_error_template => "min: %s %%",
                perfdatas => [
                    { template => '%d', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'dn' }
                ]
            }
        },
        { label => 'health-average', nlabel => 'node.health.average.percentage', set => {
                key_values => [ { name => 'avg' }, { name => 'dn' } ],
                output_template => 'average: %s %%', output_error_template => "average %s %%",
                perfdatas => [
                    { template => '%d', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'dn' }
                ]
            }
        }
    ];
}

sub prefix_nodes_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{dn} . "' health ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-node:s' => { name => 'filter_node' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result_nodes = $options{custom}->get_node_health_5m();
    $self->{nodes} = {};
    foreach my $node (@{$result_nodes->{imdata}}) {
        $node->{fabricNodeHealth5min}->{attributes}->{dn} =~ /^topology\/(.*)\/sys\/CDfabricNodeHealth5min$/; 
        my $node_dn = $1;
        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            $node_dn !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $node_dn . "': no matching filter", debug => 1);
            next;
        }
        $self->{nodes}->{$node_dn} = { 
            min => $node->{fabricNodeHealth5min}->{attributes}->{healthMin},
            current => $node->{fabricNodeHealth5min}->{attributes}->{healthLast},
            avg => $node->{fabricNodeHealth5min}->{attributes}->{healthAvg},
            dn => $node_dn 
        };
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found (try --debug)");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check fabric nodes.

=over 8

=item B<--filter-node>

Regexp filter on the pod / node name 

=item B<--warning-*>

Set warning for each health percentage value. Can be : 
--warning-health-average=90:
--warning-health-current
--warning-health-minimum

=item B<--critical-*>

Set criticai for each health percentage value. Can be : 
--critical-health-average=90:
--critical-health-current=95:
--critical-health-minimum

=back

=cut
