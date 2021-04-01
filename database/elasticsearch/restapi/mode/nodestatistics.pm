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

package database::elasticsearch::restapi::mode::nodestatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All nodes are ok' },
    ];
    
    $self->{maps_counters}->{nodes} = [
        { label => 'jvm-heap-usage', nlabel => 'node.jvm.heap.usage.percentage', set => {
                key_values => [ { name => 'heap_used_percent' }, { name => 'display' } ],
                output_template => 'JVM Heap: %d%%',
                perfdatas => [
                    { value => 'heap_used_percent', template => '%d',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'jvm-heap-usage-bytes', nlabel => 'node.jvm.heap.usage.bytes', display_ok => 0, set => {
                key_values => [ { name => 'heap_used_in_bytes' }, { name => 'heap_max_in_bytes' }, { name => 'display' } ],
                output_template => 'JVM Heap Bytes: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'heap_used_in_bytes', template => '%s',
                      min => 0, max => 'heap_max_in_bytes', unit => 'B', label_extra_instance => 1,
                      instance_use => 'display' },
                ],
            }
        },
        { label => 'disk-free', nlabel => 'node.disk.free.bytes', set => {
                key_values => [ { name => 'available_in_bytes' }, { name => 'total_in_bytes' },
                    { name => 'display' } ],
                output_template => 'Free Disk Space: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'available_in_bytes', template => '%s',
                      min => 0, max => 'total_in_bytes', unit => 'B',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'documents-total', nlabel => 'node.documents.total.count', set => {
                key_values => [ { name => 'docs_count' }, { name => 'display' } ],
                output_template => 'Documents: %d',
                perfdatas => [
                    { value => 'docs_count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'data-size', nlabel => 'node.data.size.bytes', set => {
                key_values => [ { name => 'size_in_bytes' }, { name => 'display' } ],
                output_template => 'Data: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'size_in_bytes', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};
                                                           
    my $nodes_stats = $options{custom}->get(path => '/_nodes/stats');

    foreach my $node (keys %{$nodes_stats->{nodes}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $nodes_stats->{nodes}->{$node}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $nodes_stats->{nodes}->{$node}->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{nodes}->{$node} = {
            display => $nodes_stats->{nodes}->{$node}->{name},
            indices_count => $nodes_stats->{indices}->{count},
            heap_used_percent => $nodes_stats->{nodes}->{$node}->{jvm}->{mem}->{heap_used_percent},
            heap_used_in_bytes => $nodes_stats->{nodes}->{$node}->{jvm}->{mem}->{heap_used_in_bytes},
            heap_max_in_bytes => $nodes_stats->{nodes}->{$node}->{jvm}->{mem}->{heap_max_in_bytes},
            available_in_bytes => $nodes_stats->{nodes}->{$node}->{fs}->{total}->{available_in_bytes},
            total_in_bytes => $nodes_stats->{nodes}->{$node}->{fs}->{total}->{total_in_bytes},
            docs_count => $nodes_stats->{nodes}->{$node}->{indices}->{docs}->{count},
            size_in_bytes => $nodes_stats->{nodes}->{$node}->{indices}->{store}->{size_in_bytes},
        };
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check nodes statistics.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='heap'

=item B<--warning-*>

Threshold warning.
Can be: 'data-size', 'disk-free', 'documents-total',
'jvm-heap-usage' (in %), 'jvm-heap-usage-bytes'.

=item B<--critical-*>

Threshold critical.
Can be: 'data-size', 'disk-free', 'documents-total',
'jvm-heap-usage' (in %), 'jvm-heap-usage-bytes'.

=back

=cut
