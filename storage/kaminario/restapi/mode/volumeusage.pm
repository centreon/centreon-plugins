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

package storage::kaminario::restapi::mode::volumeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'volume', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' },
    ];
    
    $self->{maps_counters}->{volume} = [
        { label => 'iops', set => {
                key_values => [ { name => 'iops_avg' }, { name => 'display' } ],
                output_template => 'Average IOPs : %s',
                perfdatas => [
                    { label => 'iops', value => 'iops_avg', template => '%s', 
                      min => 0, unit => 'iops', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'throughput', set => {
                key_values => [ { name => 'throughput_avg' }, { name => 'display' } ],
                output_template => 'Average Throughput : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'throughput', value => 'throughput_avg', template => '%s', 
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'latency-inner', set => {
                key_values => [ { name => 'latency_inner' }, { name => 'display' } ],
                output_template => 'Latency Inner : %.6fms',
                perfdatas => [
                    { label => 'latency_inner', value => 'latency_inner', template => '%.6f', 
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'latency-outer', set => {
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
        "filter-name:s"    => { name => 'filter_name' },
    });
    
    return $self;
}

sub prefix_volume_output {
    my ($self, %options) = @_;
    
    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{volume} = {};
    my $result = $options{custom}->get_performance(path => '/stats/volumes?__datapoints=1');
    foreach my $entry (@{$result->{hits}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $entry->{volume_name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $entry->{volume_name} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{volume}->{$entry->{volume_name}} = {
            display => $entry->{volume_name},
            %{$entry},
        };
    }
}

1;

__END__

=head1 MODE

Check volume usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^iops$'

=item B<--filter-name>

Filter volume name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'latency-inner', 'latency-outer', 'iops', 'throughput'

=item B<--critical-*>

Threshold critical.
Can be: 'latency-inner', 'latency-outer', 'iops', 'throughput'

=back

=cut
