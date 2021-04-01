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

package storage::kaminario::restapi::mode::systemusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'bs', type => 1, cb_prefix_output => 'prefix_bs_output', message_multiple => 'All block sizes are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'iops', set => {
                key_values => [ { name => 'iops_avg' } ],
                output_template => 'Average IOPs : %s',
                perfdatas => [
                    { label => 'iops', value => 'iops_avg', template => '%s', 
                      min => 0, unit => 'iops' },
                ],
            }
        },
        { label => 'throughput', set => {
                key_values => [ { name => 'throughput_avg' } ],
                output_template => 'Average Throughput : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'throughput', value => 'throughput_avg', template => '%s', 
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'latency-inner', set => {
                key_values => [ { name => 'latency_inner' } ],
                output_template => 'Latency Inner : %.6fms',
                perfdatas => [
                    { label => 'latency_inner', value => 'latency_inner', template => '%.6f', 
                      min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'latency-outer', set => {
                key_values => [ { name => 'latency_outer' } ],
                output_template => 'Latency Outer : %.6fms',
                perfdatas => [
                    { label => 'latency_outer', value => 'latency_outer', template => '%.6f', 
                      min => 0, unit => 'ms' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{bs} = [
        { label => 'bs-iops', set => {
                key_values => [ { name => 'iops_avg' }, { name => 'display' } ],
                output_template => 'Average IOPs : %s',
                perfdatas => [
                    { label => 'iops', value => 'iops_avg', template => '%s', 
                      min => 0, unit => 'iops', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'bs-throughput', set => {
                key_values => [ { name => 'throughput_avg' }, { name => 'display' } ],
                output_template => 'Average Throughput : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'throughput', value => 'throughput_avg', template => '%s', 
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'bs-latency-inner', set => {
                key_values => [ { name => 'latency_inner' }, { name => 'display' } ],
                output_template => 'Latency Inner : %.6fms',
                perfdatas => [
                    { label => 'latency_inner', value => 'latency_inner', template => '%.6f', 
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'bs-latency-outer', set => {
                key_values => [ { name => 'latency_outer' }, { name => 'display' } ],
                output_template => 'Latency Outer : %.6fms',
                perfdatas => [
                    { label => 'latency_outer', value => 'latency_outer', template => '%.6f', 
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "System ";
}

sub prefix_bs_output {
    my ($self, %options) = @_;
    
    return "Block size '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{bs} = {};
    my $result = $options{custom}->get_performance(path => '/stats/system?__datapoints=1&__bs_breakdown=true');
    foreach my $entry (@{$result->{hits}}) {
        $self->{bs}->{$entry->{bs}} = {
            display => $entry->{bs},
            %{$entry},
        };
    }
    
    $result = $options{custom}->get_performance(path => '/stats/system?__datapoints=1');
    $self->{global} = { %{$result->{hits}->[0]} };
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^iops$'

=item B<--warning-*>

Threshold warning.
Can be: 'latency-inner', 'latency-outer', 'iops', 'throughput',
'bs-latency-inner', 'bs-latency-outer', 'bs-iops', 'bs-throughput',

=item B<--critical-*>

Threshold critical.
Can be: 'latency-inner', 'latency-outer', 'iops', 'throughput',
'bs-latency-inner', 'bs-latency-outer', 'bs-iops', 'bs-throughput',

=back

=cut
