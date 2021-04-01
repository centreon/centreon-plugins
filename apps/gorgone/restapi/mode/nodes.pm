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

package apps::gorgone::restapi::mode::nodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All nodes are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'nodes-total', nlabel => 'nodes.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total nodes: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'ping-received-lasttime', nlabel => 'node.ping.received.lasttime.seconds', set => {
                key_values => [ { name => 'last_ping_recv' }, { name => 'last_ping_recv_human' }, { name => 'display' } ],
                output_template => 'last ping received: %s',
                output_use => 'last_ping_recv_human',
                perfdatas => [
                    { template => '%d', min => -1, unit => 's', label_extra_instance => 1 }
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
        'filter-node-id:s' => { name => 'filter_node_id' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $nodes = $options{custom}->request_api(endpoint => '/api/internal/constatus');

    $self->{global} = { total => 0 };
    $self->{nodes} = {};
    foreach my $node_id (keys %{$nodes->{data}}) {
        if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $node_id !~ /$self->{option_results}->{filter_node_id}/) {
            $self->{output}->output_add(long_msg => "skipping node '" . $node_id . "': no matching filter.", debug => 1);
            next;
        }

        my $last_ping_recv = defined($nodes->{data}->{$node_id}->{last_ping_recv}) && $nodes->{data}->{$node_id}->{last_ping_recv} != 0 ? 
            time() - $nodes->{data}->{$node_id}->{last_ping_recv} : -1;
        $self->{nodes}->{ $node_id } = {
            display => $node_id,
            last_ping_recv => $last_ping_recv,
            last_ping_recv_human => $last_ping_recv != -1 ? centreon::plugins::misc::change_seconds(value => $last_ping_recv) : $last_ping_recv
        };
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check nodes.

=over 8

=item B<--filter-node-id>

Filter nodes (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'nodes-total', 'ping-received-lasttime' (s).

=back

=cut
